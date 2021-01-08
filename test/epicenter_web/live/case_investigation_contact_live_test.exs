defmodule EpicenterWeb.CaseInvestigationContactLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "alice-test-result", ~D[2020-08-06]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "alice-case-investigation", %{
        clinical_status: "asymptomatic",
        symptom_onset_on: ~D[2020-11-03],
        symptoms: ["cough", "headache"]
      })
      |> Cases.create_case_investigation!()

    [person: person, user: user, case_investigation: case_investigation]
  end

  describe "creating" do
    test "records an audit log entry for the person associated with the case investigation", %{
      conn: conn,
      case_investigation: case_investigation,
      person: person,
      user: user
    } do
      capture_log(fn -> Pages.CaseInvestigationContact.visit(conn, case_investigation) end)
      |> AuditLogAssertions.assert_viewed_person(user, person)
    end

    test "has a case investigation view", %{conn: conn, case_investigation: case_investigation, person: person} do
      view =
        Pages.CaseInvestigationContact.visit(conn, case_investigation)
        |> Pages.CaseInvestigationContact.assert_here()

      assert %{
               "contact_form[first_name]" => "",
               "contact_form[last_name]" => "",
               "contact_form[phone]" => ""
             } = Pages.form_state(view)

      view
      |> Pages.submit_and_follow_redirect(conn, "#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "Alice",
          "last_name" => "Testuser",
          "relationship_to_case" => "Family",
          "most_recent_date_together" => "10/31/2020",
          "under_18" => "false",
          "same_household" => "true",
          "phone" => "1111111234",
          "preferred_language" => "Haitian Creole"
        }
      )
      |> Pages.Profile.assert_here(person)

      assert %{
               contact_investigations: [
                 %{
                   relationship_to_case: "Family",
                   most_recent_date_together: ~D[2020-10-31],
                   household_member: true,
                   under_18: false,
                   exposed_person: %{
                     demographics: [
                       %{
                         source: "form",
                         first_name: "Alice",
                         last_name: "Testuser",
                         preferred_language: "Haitian Creole"
                       }
                     ],
                     phones: [
                       %{
                         number: "1111111234",
                         source: "form"
                       }
                     ]
                   }
                 }
               ]
             } = Cases.get_case_investigation(case_investigation.id) |> Cases.preload_contact_investigations()
    end

    test "when the symptom onset date is available, contains value and uses it for the infectious period", %{
      conn: conn,
      case_investigation: case_investigation
    } do
      text =
        Pages.CaseInvestigationContact.visit(conn, case_investigation)
        |> render()
        |> Pages.parse()
        |> Test.Html.text()

      assert text =~ "Onset date: 11/03/2020"
      assert text =~ "Positive lab sample: 08/06/2020"
      assert text =~ "Infectious period: 11/01/2020 - 11/13/2020"
    end

    test "when the symptom onset is not available, contains the lab result's sampled on instead", %{
      conn: conn,
      case_investigation: case_investigation
    } do
      {:ok, case_investigation} = Cases.update_case_investigation(case_investigation, {%{symptom_onset_on: nil}, Test.Fixtures.admin_audit_meta()})

      text =
        Pages.CaseInvestigationContact.visit(conn, case_investigation)
        |> render()
        |> Pages.parse()
        |> Test.Html.text()

      assert text =~ "Onset date: Unavailable"
      assert text =~ "Positive lab sample: 08/06/2020"
      assert text =~ "Infectious period: 08/04/2020 - 08/16/2020"
    end

    test "when the symptom onset is not available, and the initiating lab result lacks a sampled on, shows unavailable for everything", %{
      conn: conn,
      case_investigation: case_investigation,
      person: person,
      user: user
    } do
      lab_result = Test.Fixtures.lab_result_attrs(person, user, "alice-test-result", nil) |> Cases.create_lab_result!()

      {:ok, case_investigation} =
        Cases.update_case_investigation(
          case_investigation,
          {%{symptom_onset_on: nil, initiating_lab_result_id: lab_result.id}, Test.Fixtures.admin_audit_meta()}
        )

      text =
        Pages.CaseInvestigationContact.visit(conn, case_investigation)
        |> render()
        |> Pages.parse()
        |> Test.Html.text()

      assert text =~ "Onset date: Unavailable"
      assert text =~ "Positive lab sample: Unavailable"
      assert text =~ "Infectious period: Unavailable"
    end

    test "marking a contact as under_18 collects the phone number for the guardian", %{
      conn: conn,
      case_investigation: case_investigation
    } do
      view =
        Pages.CaseInvestigationContact.visit(conn, case_investigation)
        |> Pages.CaseInvestigationContact.assert_here()

      assert %{
               "contact_form[phone]" => "Phone"
             } = Pages.form_labels(view)

      refute "contact_form[guardian_name]" in (Pages.form_labels(view) |> Map.keys())
      refute "contact_form[guardian_phone]" in (Pages.form_labels(view) |> Map.keys())

      view =
        view
        |> Pages.CaseInvestigationContact.change_form(contact_form: %{"under_18" => "true", "same_household" => "true", "first_name" => "Jared"})

      assert %{
               "contact_form[guardian_name]" => "Guardian's name",
               "contact_form[guardian_phone]" => "Guardian's phone"
             } = Pages.form_labels(view)

      refute "contact_form[phone]" in (Pages.form_labels(view) |> Map.keys())

      view
      |> Pages.submit_live("#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "Alice",
          "last_name" => "Testuser",
          "relationship_to_case" => "Family",
          "most_recent_date_together" => "10/15/2020",
          "under_18" => "true",
          "guardian_name" => "",
          "same_household" => "false",
          "guardian_phone" => ""
        }
      )

      view
      |> render()
      |> Pages.assert_validation_messages(%{
        "contact_form[guardian_name]" => "can't be blank"
      })

      view
      |> Pages.submit_and_follow_redirect(conn, "#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "David",
          "last_name" => "Testuser",
          "relationship_to_case" => "Friend",
          "most_recent_date_together" => "10/30/2020",
          "under_18" => "true",
          "same_household" => "true",
          "guardian_name" => "Cuthbert Testuser",
          "guardian_phone" => "1111111234",
          "preferred_language" => "Haitian Creole"
        }
      )

      assert %{
               contact_investigations: [
                 %{
                   relationship_to_case: "Friend",
                   most_recent_date_together: ~D[2020-10-30],
                   household_member: true,
                   under_18: true,
                   guardian_name: "Cuthbert Testuser",
                   guardian_phone: "1111111234",
                   exposed_person: %{
                     demographics: [
                       %{
                         source: "form",
                         first_name: "David",
                         last_name: "Testuser",
                         preferred_language: "Haitian Creole"
                       }
                     ],
                     phones: []
                   }
                 }
               ]
             } = Cases.get_case_investigation(case_investigation.id) |> Cases.preload_contact_investigations()
    end
  end

  describe "updating" do
    setup %{case_investigation: case_investigation} do
      {:ok, contact_investigation} =
        ContactInvestigations.create(
          {%{
             exposing_case_id: case_investigation.id,
             relationship_to_case: "Family",
             most_recent_date_together: ~D[2020-10-31],
             household_member: true,
             under_18: false,
             exposed_person: %{
               demographics: [
                 %{
                   source: "import",
                   first_name: "ImportedBilly"
                 },
                 %{
                   source: "form",
                   first_name: "Billy",
                   last_name: "Testuser",
                   preferred_language: "Haitian Creole"
                 }
               ],
               phones: [
                 %{
                   number: "1111111542"
                 }
               ]
             }
           }, Test.Fixtures.admin_audit_meta()}
        )

      [contact_investigation: contact_investigation]
    end

    test "records multiple audit log entries", %{
      conn: conn,
      case_investigation: case_investigation,
      contact_investigation: contact_investigation,
      user: user
    } do
      case_investigation = case_investigation |> Cases.preload_person()
      case_person = case_investigation.person
      exposed_person = contact_investigation.exposed_person

      capture_log(fn -> Pages.CaseInvestigationContact.visit(conn, case_investigation, contact_investigation) end)
      |> AuditLogAssertions.assert_viewed_person(user, case_person)
      |> AuditLogAssertions.assert_viewed_person(user, exposed_person)
    end

    test "prepopulates the form correctly", %{conn: conn, case_investigation: case_investigation, contact_investigation: contact_investigation} do
      view =
        Pages.CaseInvestigationContact.visit(conn, case_investigation, contact_investigation)
        |> Pages.CaseInvestigationContact.assert_here()

      assert %{
               "contact_form[first_name]" => "Billy",
               "contact_form[last_name]" => "Testuser",
               "contact_form[phone]" => "1111111542",
               "contact_form[under_18]" => "false",
               "contact_form[same_household]" => "true",
               "contact_form[most_recent_date_together]" => "10/31/2020",
               "contact_form[preferred_language]" => "Haitian Creole",
               "contact_form[relationship_to_case]" => "Family"
             } = Pages.form_state(view)

      {:ok, contact_investigation} =
        ContactInvestigations.update(
          contact_investigation,
          {%{
             under_18: true,
             guardian_name: "Someone",
             guardian_phone: "1111111928"
           }, Test.Fixtures.admin_audit_meta()}
        )

      view =
        Pages.CaseInvestigationContact.visit(conn, case_investigation, contact_investigation)
        |> Pages.CaseInvestigationContact.assert_here()

      assert %{
               "contact_form[first_name]" => "Billy",
               "contact_form[last_name]" => "Testuser",
               "contact_form[under_18]" => "true",
               "contact_form[guardian_name]" => "Someone",
               "contact_form[guardian_phone]" => "1111111928",
               "contact_form[same_household]" => "true",
               "contact_form[most_recent_date_together]" => "10/31/2020",
               "contact_form[preferred_language]" => "Haitian Creole",
               "contact_form[relationship_to_case]" => "Family"
             } = Pages.form_state(view)
    end

    test "works", %{conn: conn, case_investigation: case_investigation, contact_investigation: contact_investigation} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation, contact_investigation)
      |> Pages.CaseInvestigationContact.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "Cindy",
          "last_name" => "Testuser",
          "relationship_to_case" => "Friend",
          "most_recent_date_together" => "11/02/2020",
          "under_18" => "false",
          "same_household" => "false",
          "phone" => "1111111321",
          "preferred_language" => "English"
        }
      )

      assert %{
               contact_investigations: [
                 %{
                   relationship_to_case: "Friend",
                   most_recent_date_together: ~D[2020-11-02],
                   household_member: false,
                   under_18: false,
                   exposed_person: %{
                     demographics: [
                       %{
                         source: "import",
                         first_name: "ImportedBilly"
                       },
                       %{
                         source: "form",
                         first_name: "Cindy",
                         last_name: "Testuser",
                         preferred_language: "English"
                       }
                     ],
                     phones: [
                       %{
                         number: "1111111542"
                       },
                       %{
                         source: "form",
                         number: "1111111321"
                       }
                     ]
                   }
                 }
               ]
             } = Cases.get_case_investigation(case_investigation.id) |> Cases.preload_contact_investigations()
    end
  end

  describe "validations" do
    test "validates the fields when creating a contact investigation", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.CaseInvestigationContact.visit(conn, case_investigation)
        |> Pages.CaseInvestigationContact.assert_here()

      assert %{
               "contact_form[first_name]" => "",
               "contact_form[last_name]" => "",
               "contact_form[phone]" => ""
             } = Pages.form_state(view)

      view
      |> Pages.submit_live("#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "",
          "last_name" => "",
          "most_recent_date_together" => "",
          "under_18" => "false",
          "same_household" => "false",
          "phone" => ""
        }
      )
      |> Pages.assert_validation_messages(%{
        "contact_form[first_name]" => "can't be blank",
        "contact_form[last_name]" => "can't be blank",
        "contact_form[most_recent_date_together]" => "can't be blank",
        "contact_form[relationship_to_case]" => "can't be blank"
      })
      |> Pages.submit_live("#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "Alice",
          "last_name" => "Testuser",
          "relationship_to_case" => "Family",
          "most_recent_date_together" => "10/32/2020",
          "under_18" => "false",
          "same_household" => "false",
          "phone" => ""
        }
      )
      |> Pages.assert_validation_messages(%{
        "contact_form[most_recent_date_together]" => "must be a valid MM/DD/YYYY date"
      })
    end

    test "shows validation errors on submit", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation)
      |> Pages.assert_validation_messages(%{})
      |> Pages.refute_save_error()
      |> Pages.submit_live("#case-investigation-contact-form", complete_interview_contact_form: %{})
      |> Pages.assert_validation_messages(%{
        "contact_form[first_name]" => "can't be blank",
        "contact_form[last_name]" => "can't be blank",
        "contact_form[most_recent_date_together]" => "can't be blank",
        "contact_form[relationship_to_case]" => "can't be blank"
      })
      |> Pages.assert_save_error("Check errors above")
    end

    test "it doesn't crash when there are last name validation errors", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation)
      |> Pages.CaseInvestigationContact.assert_here()
      |> Pages.submit_live("#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "harry",
          "last_name" => "potter",
          "most_recent_date_together" => "12/16/2020",
          "under_18" => "false",
          "same_household" => "false",
          "relationship_to_case" => "Family"
        }
      )
      |> Pages.assert_validation_messages(%{
        "contact_form[last_name]" => "In non-PHI environment, must start with 'Testuser'"
      })
    end

    test "it doesn't crash when there are guardian phone validation errors", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation)
      |> Pages.CaseInvestigationContact.assert_here()
      |> Pages.CaseInvestigationContact.change_form(
        contact_form: %{
          "under_18" => "true",
          "same_household" => "true",
          "first_name" => "Jared"
        }
      )
      |> Pages.submit_live("#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "Alice",
          "last_name" => "Testuser",
          "relationship_to_case" => "Family",
          "most_recent_date_together" => "10/15/2020",
          "under_18" => "true",
          "guardian_name" => "Cuthbert Testuser",
          "same_household" => "false",
          "guardian_phone" => "3031231234"
        }
      )
      |> render()
      |> Pages.assert_validation_messages(%{
        "contact_form[guardian_phone]" => "In non-PHI environment, must match '111-111-1xxx'"
      })
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes something", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation)
      |> Pages.CaseInvestigationContact.change_form(contact_form: %{"first_name" => "Alice"})
      |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")
    end
  end
end
