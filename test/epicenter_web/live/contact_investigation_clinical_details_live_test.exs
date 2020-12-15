defmodule EpicenterWeb.ContactInvestigationClinicalDetailsLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  import Epicenter.Test.RevisionAssertions

  setup :register_and_log_in_user

  setup %{user: user} do
    sick_person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Cases.create_person!()

    lab_result =
      Test.Fixtures.lab_result_attrs(sick_person, user, "lab_result", ~D[2020-08-07])
      |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(sick_person, lab_result, user, "the contagious person's case investigation")
      |> Cases.create_case_investigation!()

    {:ok, contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs("contact_investigation", %{
         exposing_case_id: case_investigation.id,
         most_recent_date_together: ~D[2020-12-15],
         exposed_on: ~D[2020-12-14],
         clinical_status: "asymptomatic",
         symptoms: ["cough", "headache"]
       }), Test.Fixtures.admin_audit_meta()}
      |> Cases.create_contact_investigation()

    [contact_investigation: contact_investigation, user: user]
  end

  test "has a contact investigation view", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationClinicalDetails.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationClinicalDetails.assert_here()
    |> Pages.ContactInvestigationClinicalDetails.assert_clinical_status_selection(%{
      "Unknown" => false,
      "Symptomatic" => false,
      "Asymptomatic" => true
    })
    |> Pages.ContactInvestigationClinicalDetails.assert_exposed_on_explanation_text("12/15/2020")
    |> Pages.ContactInvestigationClinicalDetails.assert_exposed_on_value("12/14/2020")
    |> Pages.ContactInvestigationClinicalDetails.assert_symptoms_selection(%{
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
    |> Pages.ContactInvestigationClinicalDetails.assert_save_button_visible()
  end

  test "saving clinical details", %{conn: conn, contact_investigation: contact_investigation, user: user} do
    Pages.ContactInvestigationClinicalDetails.visit(conn, contact_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "exposed_on" => "09/06/2020",
        "symptoms" => ["fever", "chills"]
      }
    )
    |> Pages.Profile.assert_here(contact_investigation.exposed_person)

    assert_revision_count(contact_investigation, 2)

    assert_recent_audit_log(contact_investigation, user, %{
      clinical_status: "symptomatic",
      exposed_on: "2020-09-06",
      symptoms: ["fever", "chills"]
    })

    assert_recent_audit_log(
      contact_investigation,
      user,
      action: "update-contact-investigation",
      event: "edit-contact-investigation-clinical-details"
    )
  end

  test "saving empty clinical details", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationClinicalDetails.visit(conn, contact_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-clinical-details-form",
      clinical_details_form: %{
        "exposed_on" => "",
        "symptoms" => []
      }
    )
    |> Pages.Profile.assert_here(contact_investigation.exposed_person)

    contact_investigation = Cases.get_contact_investigation(contact_investigation.id)
    assert Euclid.Exists.blank?(contact_investigation.symptoms)
    assert contact_investigation.exposed_on == nil
    assert contact_investigation.clinical_status == "asymptomatic"
  end

  test "validating date format", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationClinicalDetails.visit(conn, contact_investigation)
    |> Pages.submit_live("#contact-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "exposed_on" => "09/32/2020",
        "symptoms" => ["fever", "chills"]
      }
    )
    |> Pages.assert_validation_messages(%{"clinical_details_form[exposed_on]" => "must be a valid MM/DD/YYYY date"})
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationClinicalDetails.visit(conn, contact_investigation)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes something", %{conn: conn, contact_investigation: contact_investigation} do
      view =
        Pages.ContactInvestigationClinicalDetails.visit(conn, contact_investigation)
        |> Pages.ContactInvestigationClinicalDetails.change_form(clinical_details_form: %{"clinical_status" => "symptomatic"})
        |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")

      assert %{
               "clinical_details_form[clinical_status]" => "symptomatic"
             } = Pages.form_state(view)
    end
  end
end
