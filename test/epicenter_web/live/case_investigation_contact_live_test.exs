defmodule EpicenterWeb.CaseInvestigationContactLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
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
        symptom_onset_date: ~D[2020-11-03],
        symptoms: ["cough", "headache"]
      })
      |> Cases.create_case_investigation!()

    [person: person, user: user, case_investigation: case_investigation]
  end

  describe "creating" do
    test "has a case investigation view", %{conn: conn, case_investigation: case_investigation, person: person} do
      view =
        Pages.CaseInvestigationContact.visit(conn, case_investigation)
        |> Pages.CaseInvestigationContact.assert_here()

      assert %{
               "contact_form[first_name]" => nil,
               "contact_form[last_name]" => nil,
               "contact_form[relationship_to_case]" => "",
               "contact_form[preferred_language]" => "",
               "contact_form[phone]" => ""
             } = Pages.form_state(view)

      view
      |> Pages.submit_and_follow_redirect(conn, "#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "Alice",
          "last_name" => "Testuser",
          "relationship_to_case" => "Family",
          "most_recent_date_together" => "10/31/2020",
          "under_18" => "true",
          "same_household" => "true",
          "phone" => "1111111234",
          "preferred_language" => "Haitian Creole"
        }
      )
      |> Pages.Profile.assert_here(person)

      assert %{
               exposures: [
                 %{
                   relationship_to_case: "Family",
                   most_recent_date_together: ~D[2020-10-31],
                   household_member: true,
                   under_18: true,
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
             } = Cases.get_case_investigation(case_investigation.id) |> Cases.preload_exposures()
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
      {:ok, case_investigation} = Cases.update_case_investigation(case_investigation, {%{symptom_onset_date: nil}, Test.Fixtures.admin_audit_meta()})

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
          {%{symptom_onset_date: nil, initiating_lab_result_id: lab_result.id}, Test.Fixtures.admin_audit_meta()}
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

    test "validates the fields", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.CaseInvestigationContact.visit(conn, case_investigation)
        |> Pages.CaseInvestigationContact.assert_here()

      assert %{
               "contact_form[first_name]" => nil,
               "contact_form[last_name]" => nil,
               "contact_form[phone]" => ""
             } = Pages.form_state(view)

      view
      |> Pages.submit_live("#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "",
          "last_name" => "",
          "relationship_to_case" => "",
          "most_recent_date_together" => "",
          "under_18" => "false",
          "same_household" => "false",
          "phone" => ""
        }
      )

      view
      |> render()
      |> Pages.assert_validation_messages(%{
        "contact_form_first_name" => "can't be blank",
        "contact_form_last_name" => "can't be blank",
        "contact_form_most_recent_date_together" => "can't be blank",
        "contact_form_relationship_to_case" => "can't be blank"
      })

      view
      |> Pages.submit_live("#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "Alice",
          "last_name" => "Testuser",
          "relationship_to_case" => "neighbor",
          "most_recent_date_together" => "10/32/2020",
          "under_18" => "false",
          "same_household" => "false",
          "phone" => ""
        }
      )

      view
      |> render()
      |> Pages.assert_validation_messages(%{
        "contact_form_most_recent_date_together" => "must be MM/DD/YYYY"
      })
    end
  end

  describe "updating" do
    setup %{case_investigation: case_investigation} do
      {:ok, exposure} =
        Cases.create_exposure(
          {%{
             exposing_case_id: case_investigation.id,
             relationship_to_case: "spouse",
             most_recent_date_together: ~D[2020-10-31],
             household_member: true,
             under_18: false,
             exposed_person: %{
               demographics: [
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

      [exposure: exposure]
    end

    test "prepopulates the form correctly", %{conn: conn, case_investigation: case_investigation, exposure: exposure} do
      view =
        Pages.CaseInvestigationContact.visit(conn, case_investigation, exposure)
        |> Pages.CaseInvestigationContact.assert_here()

      assert %{
               "contact_form[first_name]" => "Billy",
               "contact_form[last_name]" => "Testuser",
               "contact_form[phone]" => "1111111542",
               "contact_form[under_18]" => "false",
               "contact_form[same_household]" => "true",
               "contact_form[most_recent_date_together]" => "10/31/2020",
               "contact_form[preferred_language]" => "Haitian Creole",
               "contact_form[relationship_to_case]" => "spouse"
             } = Pages.form_state(view)
    end

    test "works", %{conn: conn, case_investigation: case_investigation, exposure: exposure} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation, exposure)
      |> Pages.CaseInvestigationContact.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#case-investigation-contact-form",
        contact_form: %{
          "first_name" => "Cindy",
          "last_name" => "Testuser",
          "relationship_to_case" => "Friend",
          "most_recent_date_together" => "11/02/2020",
          "under_18" => "true",
          "same_household" => "false",
          "phone" => "1111111321",
          "preferred_language" => "English"
        }
      )

      assert %{
               exposures: [
                 %{
                   relationship_to_case: "Friend",
                   most_recent_date_together: ~D[2020-11-02],
                   household_member: false,
                   under_18: true,
                   exposed_person: %{
                     demographics: [
                       %{
                         source: "form",
                         first_name: "Cindy",
                         last_name: "Testuser",
                         preferred_language: "English"
                       }
                     ],
                     phones: [
                       %{
                         source: "form",
                         number: "1111111321"
                       }
                     ]
                   }
                 }
               ]
             } = Cases.get_case_investigation(case_investigation.id) |> Cases.preload_exposures()
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation)
      |> Pages.assert_confirmation_prompt("")
    end

    test "when the user changes something", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation)
      |> Pages.CaseInvestigationContact.change_form(%{"first_name" => "Alice"})
      |> Pages.assert_confirmation_prompt("Your updates have not been saved. Discard updates?")
    end
  end
end
