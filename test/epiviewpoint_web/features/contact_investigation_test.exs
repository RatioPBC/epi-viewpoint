defmodule EpiViewpointWeb.Features.ContactInvestigationTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Cases
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Components
  alias EpiViewpointWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    sick_person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(sick_person, user, "lab_result", ~D[2020-08-07]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(sick_person, lab_result, user, "the contagious person's case investigation")
      |> Cases.create_case_investigation!()

    {:ok, contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs("contact_investigation", %{exposing_case_id: case_investigation.id}),
       Test.Fixtures.admin_audit_meta()}
      |> ContactInvestigations.create()

    exposed_person = Cases.get_person(contact_investigation.exposed_person_id, user)

    [contact_investigation: contact_investigation, exposed_person: exposed_person]
  end

  test "user can discontinue a contact investigation", %{conn: conn, contact_investigation: contact_investigation, exposed_person: exposed_person} do
    conn
    |> Pages.Profile.visit(exposed_person)
    |> Pages.Profile.assert_here(exposed_person)
    |> EpiViewpoint.Extra.tap(fn view ->
      assert [%{interview_status: "Pending"}] = Pages.Profile.contact_investigations(view)
    end)
    |> Pages.Profile.click_discontinue_contact_investigation(contact_investigation.tid)
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ContactInvestigationDiscontinue.assert_here(contact_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-discontinue-form",
      contact_investigation: %{"interview_discontinue_reason" => "Unable to reach"}
    )
    |> Pages.Profile.assert_here(contact_investigation.exposed_person)
    |> EpiViewpoint.Extra.tap(fn view ->
      assert [%{interview_status: "Discontinued"}] = Pages.Profile.contact_investigations(view)
    end)
  end

  test "user can conduct a contact investigation", %{conn: conn, contact_investigation: contact_investigation, exposed_person: exposed_person} do
    conn
    |> Pages.Profile.visit(exposed_person)
    |> Pages.Profile.assert_here(exposed_person)
    |> EpiViewpoint.Extra.tap(fn view ->
      assert [%{interview_status: "Pending"}] = Pages.Profile.contact_investigations(view)
    end)
    |> Pages.Profile.click_start_contact_investigation(contact_investigation.tid)
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ContactInvestigationStartInterview.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-interview-start-form",
      start_interview_form: %{
        "person_interviewed" => "Alice's guardian",
        "date_started" => "09/06/2020",
        "time_started" => "03:45",
        "time_started_am_pm" => "PM"
      }
    )
    |> Pages.Profile.assert_here(contact_investigation.exposed_person)
    |> EpiViewpoint.Extra.tap(fn view ->
      assert [
               %{
                 interview_buttons: ["Complete interview", "Discontinue"],
                 interview_history_items: ["Started interview with proxy Alice's guardian on 09/06/2020 at 03:45pm EDT"],
                 interview_status: "Ongoing"
               }
             ] = Pages.Profile.contact_investigations(view)
    end)
    |> Pages.Profile.click_edit_contact_clinical_details_link(contact_investigation.tid)
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ContactInvestigationClinicalDetails.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "exposed_on" => "09/06/2020",
        "symptoms" => ["fever", "chills"]
      }
    )
    |> Pages.Profile.assert_here(contact_investigation.exposed_person)
    |> Components.ContactInvestigation.assert_clinical_details(%{
      clinical_status: "Symptomatic",
      exposed_on: "09/06/2020",
      symptoms: "Fever > 100.4F, Chills"
    })
    |> EpiViewpoint.Extra.tap(fn view ->
      assert [
               %{
                 interview_buttons: ["Complete interview", "Discontinue"],
                 interview_history_items: ["Started interview with proxy Alice's guardian on 09/06/2020 at 03:45pm EDT"],
                 interview_status: "Ongoing",
                 quarantine_monitoring_buttons: []
               }
             ] = Pages.Profile.contact_investigations(view)
    end)
    |> Pages.Profile.click_contact_investigation_complete_interview(contact_investigation.tid)
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.InvestigationCompleteInterview.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#investigation-interview-complete-form",
      complete_interview_form: %{
        "date_completed" => "09/06/2020",
        "time_completed" => "03:45",
        "time_completed_am_pm" => "PM"
      }
    )
    |> Pages.Profile.assert_here(exposed_person)
    |> Components.ContactInvestigation.assert_clinical_details(%{
      clinical_status: "Symptomatic",
      exposed_on: "09/06/2020",
      symptoms: "Fever > 100.4F, Chills"
    })
    |> EpiViewpoint.Extra.tap(fn view ->
      assert [
               %{
                 interview_buttons: [],
                 interview_history_items: [
                   "Started interview with proxy Alice's guardian on 09/06/2020 at 03:45pm EDT",
                   "Completed interview on 09/06/2020 at 03:45pm EDT"
                 ],
                 interview_status: "Completed",
                 quarantine_monitoring_buttons: ["Add quarantine dates"],
                 quarantine_status: "Pending quarantine monitoring",
                 quarantine_history_items: []
               }
             ] = Pages.Profile.contact_investigations(view)
    end)
    |> Pages.Profile.click_contact_investigation_quarantine_monitoring(contact_investigation.tid)
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ContactInvestigationQuarantineMonitoring.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-quarantine-monitoring-form",
      quarantine_monitoring_form: %{
        "date_started" => "11/01/2020",
        "date_ended" => "11/15/2020"
      }
    )
    |> Pages.Profile.assert_here(exposed_person)
    |> EpiViewpoint.Extra.tap(fn view ->
      assert [
               %{
                 quarantine_monitoring_buttons: ["Conclude monitoring"],
                 quarantine_status: "Ongoing quarantine monitoring (15 days remaining)",
                 quarantine_history_items: ["Quarantine dates: 11/01/2020 - 11/15/2020"]
               }
             ] = Pages.Profile.contact_investigations(view)
    end)
    |> Pages.Profile.click_edit_contact_investigation_quarantine_monitoring(contact_investigation.tid)
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ContactInvestigationQuarantineMonitoring.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-quarantine-monitoring-form",
      quarantine_monitoring_form: %{
        "date_started" => "12/01/2020",
        "date_ended" => "12/15/2020"
      }
    )
    |> Pages.Profile.assert_here(exposed_person)
    |> EpiViewpoint.Extra.tap(fn view ->
      assert [
               %{
                 quarantine_history_items: ["Quarantine dates: 12/01/2020 - 12/15/2020"]
               }
             ] = Pages.Profile.contact_investigations(view)
    end)
    |> Pages.Profile.click_conclude_contact_investigation_quarantine_monitoring(contact_investigation.tid)
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ContactInvestigationConcludeQuarantineMonitoring.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-conclude-quarantine-monitoring-form",
      conclude_quarantine_monitoring_form: %{
        "reason" => "successfully_completed_quarantine"
      }
    )
    |> Pages.Profile.assert_here(exposed_person)
    |> EpiViewpoint.Extra.tap(fn view ->
      assert [
               %{
                 quarantine_monitoring_buttons: [],
                 quarantine_status: "Concluded quarantine monitoring",
                 quarantine_history_items: [
                   "Quarantine dates: 12/01/2020 - 12/15/2020",
                   "Concluded quarantine monitoring on 10/31/2020: Successfully completed quarantine period"
                 ]
               }
             ] = Pages.Profile.contact_investigations(view)
    end)
    |> Pages.Profile.click_edit_conclude_contact_investigation_quarantine_monitoring(contact_investigation.tid)
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ContactInvestigationConcludeQuarantineMonitoring.assert_here()
  end
end
