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
               "contact_form[phone]" => ""
             } = Pages.form_state(view)

      view
      |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
        contact_form: %{
          "first_name" => "Alice",
          "last_name" => "Testuser",
          "relationship_to_case" => "Family",
          "most_recent_date_together" => "10/31/2020",
          "under_18" => "true",
          "same_household" => "true",
          "phone" => "1111111234"
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
                         last_name: "Testuser"
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
             } = Cases.get_case_investigation(case_investigation.id) |> Epicenter.Repo.preload(exposures: [exposed_person: [:demographics, :phones]])
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
      |> Pages.submit_live("#case-investigation-clinical-details-form",
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
      |> assert_validation_messages(%{
        "contact_form_first_name" => "can't be blank",
        "contact_form_last_name" => "can't be blank",
        "contact_form_most_recent_date_together" => "can't be blank",
        "contact_form_relationship_to_case" => "can't be blank"
      })

      view
      |> Pages.submit_live("#case-investigation-clinical-details-form",
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
      |> assert_validation_messages(%{
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
                   last_name: "Testuser"
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
               "contact_form[relationship_to_case]" => "spouse"
             } = Pages.form_state(view)
    end

    test "works", %{conn: conn, case_investigation: case_investigation, exposure: exposure} do
      Pages.CaseInvestigationContact.visit(conn, case_investigation, exposure)
      |> Pages.CaseInvestigationContact.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
        contact_form: %{
          "first_name" => "Cindy",
          "last_name" => "Testuser",
          "relationship_to_case" => "Friend",
          "most_recent_date_together" => "11/02/2020",
          "under_18" => "true",
          "same_household" => "false",
          "phone" => "1111111321"
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
                         last_name: "Testuser"
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
             } = Cases.get_case_investigation(case_investigation.id) |> Epicenter.Repo.preload(exposures: [exposed_person: [:demographics, :phones]])
    end
  end
end
