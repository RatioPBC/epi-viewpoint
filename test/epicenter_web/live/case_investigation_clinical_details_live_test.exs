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
      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "alice-case-investigation", %{
        clinical_status: "asymptomatic",
        symptom_onset_on: ~D[2020-11-03],
        symptoms: ["cough", "headache"]
      })
      |> Cases.create_case_investigation!()

    [person: person, user: user, case_investigation: case_investigation]
  end

  test "records an audit log entry", %{conn: conn, case_investigation: case_investigation, user: user} do
    case_investigation = case_investigation |> Cases.preload_person()

    capture_log(fn -> Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation) end)
    |> AuditLogAssertions.assert_viewed_person(user, case_investigation.person)
  end

  test "has a clinical details form", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.CaseInvestigationClinicalDetails.assert_here()
    |> Pages.CaseInvestigationClinicalDetails.assert_clinical_status_selection(%{
      "Unknown" => false,
      "Symptomatic" => false,
      "Asymptomatic" => true
    })
    |> Pages.CaseInvestigationClinicalDetails.assert_symptom_onset_on_explanation_text("08/06/2020")
    |> Pages.CaseInvestigationClinicalDetails.assert_symptom_onset_on_value("11/03/2020")
    |> Pages.CaseInvestigationClinicalDetails.assert_symptoms_selection(%{
      "Fever > 100.4F" => false,
      "Subjective fever (felt feverish)" => false,
      "Cough" => true,
      "Shortness of breath" => false,
      "Diarrhea/GI" => false,
      "Headache" => true,
      "Muscle ache" => false,
      "Chills" => false,
      "Sore throat" => false,
      "Vomiting" => false,
      "Abdominal pain" => false,
      "Nasal congestion" => false,
      "Loss of sense of smell" => false,
      "Loss of sense of taste" => false,
      "Fatigue" => false,
      "Other" => false
    })
    |> Pages.CaseInvestigationClinicalDetails.assert_save_button_visible()
  end

  @tag :skip
  test "saving clinical details with progressive disclosure of 'Other' text box", %{
    conn: conn,
    case_investigation: case_investigation,
    person: person,
    user: user
  } do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_on" => "09/06/2020",
        "symptoms" => ["fever", "chills", "groggy"],
        "symptoms_other" => true
      }
    )
    |> Pages.Profile.assert_here(person)

    assert_revision_count(case_investigation, 2)

    assert_recent_audit_log(case_investigation, user, %{
      clinical_status: "symptomatic",
      symptom_onset_on: "2020-09-06",
      symptoms: ["fever", "chills", "groggy"]
    })
  end

  # Fixes #176181002 - we had misnamed the key to check for in the params passed to handle_event("change", ...)
  test "changed symptoms are rendered correctly", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.CaseInvestigationClinicalDetails.change_form(clinical_details_form: %{"symptoms" => ["cough"]})
    |> Pages.CaseInvestigationClinicalDetails.assert_symptoms_selection(%{
      "Fever > 100.4F" => false,
      "Subjective fever (felt feverish)" => false,
      "Cough" => true,
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
      "Fatigue" => false,
      "Other" => false
    })
  end

  test "removing the last symptom doesn't clear the rendered changeset", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.CaseInvestigationClinicalDetails.change_form(clinical_details_form: %{"symptoms" => []})
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
      "Fatigue" => false,
      "Other" => false
    })
  end

  test "saving clinical details", %{conn: conn, case_investigation: case_investigation, person: person, user: user} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_on" => "09/06/2020",
        "symptoms" => ["fever", "chills"]
      }
    )
    |> Pages.Profile.assert_here(person)

    assert_revision_count(case_investigation, 2)

    assert_recent_audit_log(case_investigation, user, %{
      clinical_status: "symptomatic",
      symptom_onset_on: "2020-09-06",
      symptoms: ["fever", "chills"]
    })
  end

  @tag :skip
  test "saving clinical details with an 'Other' symptom", %{conn: conn, case_investigation: case_investigation, person: person, user: user} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_on" => "09/06/2020",
        "symptoms" => ["fever", "chills"],
        "symptoms_other" => true
      }
    )
    |> Pages.Profile.assert_here(person)

    assert_revision_count(case_investigation, 2)

    assert_recent_audit_log(case_investigation, user, %{
      clinical_status: "symptomatic",
      symptom_onset_on: "2020-09-06",
      symptoms: ["fever", "chills"]
    })
  end

  test "saving empty clinical details", %{conn: conn, case_investigation: case_investigation, person: person, user: user} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "symptom_onset_on" => "",
        "symptoms" => []
      }
    )
    |> Pages.Profile.assert_here(person)

    case_investigation = Cases.get_case_investigation(case_investigation.id, user)
    assert Euclid.Exists.blank?(case_investigation.symptoms)
    assert case_investigation.symptom_onset_on == nil
    assert case_investigation.clinical_status == "asymptomatic"
  end

  test "validating date format", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.submit_live("#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_on" => "09/32/2020",
        "symptoms" => ["fever", "chills"]
      }
    )
    |> Pages.assert_validation_messages(%{"clinical_details_form[symptom_onset_on]" => "please enter dates as mm/dd/yyyy"})
  end

  @tag :skip
  test "stripping out 'other' when submitting without other checked", %{conn: conn, case_investigation: case_investigation, user: user} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_on" => "09/02/2020",
        "symptoms" => ["fever", "groggy"]
      }
    )

    assert %{symptoms: ["fever"]} = Cases.get_case_investigation(case_investigation.id, user)
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes something", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
        |> Pages.CaseInvestigationClinicalDetails.change_form(clinical_details_form: %{"clinical_status" => "symptomatic"})
        |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")

      assert %{
               "clinical_details_form[clinical_status]" => "symptomatic"
             } = Pages.form_state(view)
    end
  end
end
