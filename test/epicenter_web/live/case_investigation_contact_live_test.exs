defmodule EpicenterWeb.CaseInvestigationContactLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  import Epicenter.Test.RevisionAssertions
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
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      contact_form: %{
        "first_name" => "Alice",
        "last_name" => "Testuser",
        "relationship_to_case" => "Family",
        "most_recent_date_together" => "10/31/2020",
        "under_18" => "true",
        "same_household" => "true",
        "phone" => "3035551234"
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
                   ]
                 }
               }
             ]
           } = Cases.get_case_investigation(case_investigation.id) |> Epicenter.Repo.preload(exposures: [exposed_person: [:demographics]])
  end
end
