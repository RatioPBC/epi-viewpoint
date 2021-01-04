defmodule EpicenterWeb.ContactInvestigationCompleteInterviewLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "investigation", %{interview_started_at: ~N[2020-01-01 22:03:07]})
      |> Cases.create_case_investigation!()

    {:ok, contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs("contact_investigation", %{exposing_case_id: case_investigation.id}),
       Test.Fixtures.admin_audit_meta()}
      |> Cases.create_contact_investigation()

    [contact_investigation: contact_investigation, user: user]
  end

  test "saving complete contact investigation", %{conn: conn, contact_investigation: contact_investigation, user: user} do
    refute contact_investigation.interview_completed_at

    Pages.ContactInvestigationCompleteInterview.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationCompleteInterview.assert_header("Complete interview")
    |> Pages.submit_and_follow_redirect(conn, "#investigation-interview-complete-form",
      complete_interview_form: %{
        "date_completed" => "09/06/2020",
        "time_completed" => "03:45",
        "time_completed_am_pm" => "PM"
      }
    )
    |> Pages.Profile.assert_here(contact_investigation.exposed_person)

    contact_investigation = Cases.get_contact_investigation(contact_investigation.id)
    assert contact_investigation.interview_completed_at
    assert Timex.to_datetime({{2020, 9, 6}, {19, 45, 0}}, "UTC") == contact_investigation.interview_completed_at
    assert_recent_audit_log(contact_investigation, user, action: "update-contact-investigation", event: "complete-contact-investigation-interview")
  end

  test "editing complete contact investigation", %{conn: conn, contact_investigation: contact_investigation, user: user} do
    {:ok, contact_investigation} =
      Cases.update_contact_investigation(contact_investigation, {
        %{interview_completed_at: ~U[2020-01-02 16:18:42Z]},
        %AuditLog.Meta{
          author_id: user.id,
          reason_action: AuditLog.Revision.update_contact_investigation_action(),
          reason_event: AuditLog.Revision.complete_contact_investigation_interview_event()
        }
      })

    Pages.ContactInvestigationCompleteInterview.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationCompleteInterview.assert_header("Edit interview")
    |> Pages.ContactInvestigationCompleteInterview.assert_time_completed("11:18", "AM")
    |> Pages.ContactInvestigationCompleteInterview.assert_date_completed("01/02/2020")
  end
end
