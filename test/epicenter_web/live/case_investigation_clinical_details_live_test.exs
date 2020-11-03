defmodule EpicenterWeb.CaseInvestigationClinicalDetailsLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  import Epicenter.Test.RevisionAssertions

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "alice-test-result", ~D[2020-08-06]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "alice-case-investigation") |> Cases.create_case_investigation!()

    [person: person, user: user, case_investigation: case_investigation]
  end

  test "has a case investigation view", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.CaseInvestigationClinicalDetails.assert_here()
    |> Pages.CaseInvestigationClinicalDetails.assert_clinical_status_selection(%{
      "Unknown" => false,
      "Symptomatic" => false,
      "Asymptomatic" => false
    })
    |> Pages.CaseInvestigationClinicalDetails.assert_symptom_onset_date_explanation_text("08/06/2020")
    |> Pages.CaseInvestigationClinicalDetails.assert_symptom_onset_date_value("")
    |> Pages.CaseInvestigationClinicalDetails.assert_symptoms_selection(%{
      "Fever > 100.4F" => false,
      "Subjective fever (felt feverish)" => false,
      "Cough" => false,
      "Shortness of breath" => false,
      "Diarrhea/GI" => false,
      "Headache" => false,
      "Muscle ache" => false,
      "Chills" => false,
      "Sore throat" => false,
      "Vomiting" => false,
      "Abdominal pain" => false,
      "Nasal congestion" => false,
      "Loss of sense of smell" => false,
      "Loss of sense of taste" => false,
      "Fatigue" => false
    })
  end

  test "saving clinical details", %{conn: conn, case_investigation: case_investigation, person: person, user: user} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_date" => "09/06/2020",
        "symptoms" => ["fever", "chills"]
      }
    )
    |> Pages.Profile.assert_here(person)

    assert_revision_count(case_investigation, 2)

    assert_recent_audit_log(case_investigation, user, %{
      clinical_status: "symptomatic",
      symptom_onset_date: "2020-09-06",
      symptoms: ["fever", "chills"]
    })
  end
end
