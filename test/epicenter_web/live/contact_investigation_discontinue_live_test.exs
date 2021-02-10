defmodule EpicenterWeb.ContactInvestigationDiscontinueLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    [contact_investigation: create_contact_investigation(user)]
  end

  test "has a working initial render", %{conn: conn, contact_investigation: contact_investigation} do
    {:ok, page_live, disconnected_html} = live(conn, "/contact-investigations/#{contact_investigation.id}/discontinue")

    assert_has_role(disconnected_html, "contact-investigation-discontinue-page")
    assert_has_role(page_live, "contact-investigation-discontinue-page")
  end

  test "records an audit log entry", %{conn: conn, contact_investigation: contact_investigation, user: user} do
    AuditLogAssertions.expect_phi_view_logs(2)
    Pages.ContactInvestigationDiscontinue.visit(conn, contact_investigation)
    AuditLogAssertions.verify_phi_view_logged(user, contact_investigation.exposed_person)
  end

  test "initial values", %{conn: conn, contact_investigation: contact_investigation} do
    view = Pages.ContactInvestigationDiscontinue.visit(conn, contact_investigation)

    assert %{
             "contact_investigation[interview_discontinue_reason]" => ""
           } = Pages.form_state(view)

    assert Pages.form_labels(view) |> Map.get("contact_investigation[interview_discontinue_reason]") ==
             [
               "Other",
               "Deceased",
               "Transferred to another jurisdiction",
               "Another contact investigation already underway",
               "Unable to reach"
             ]

    assert Pages.ContactInvestigationDiscontinue.form_title(view) == "Discontinue interview"
  end

  test "allows the user to set a discontinuation reason and saves a timestamp of when that happened", %{
    conn: conn,
    contact_investigation: contact_investigation,
    user: user
  } do
    Pages.ContactInvestigationDiscontinue.visit(conn, contact_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-discontinue-form",
      contact_investigation: %{"interview_discontinue_reason" => "Unable to reach"}
    )
    |> Pages.Profile.assert_here(contact_investigation.exposed_person)

    updated_contact_investigation = ContactInvestigations.get(contact_investigation.id, user)
    assert "Unable to reach" = updated_contact_investigation.interview_discontinue_reason
    assert_datetime_approximate(updated_contact_investigation.interview_discontinued_at, DateTime.utc_now(), 2)

    user_id = user.id
    expected_action = Revision.update_contact_investigation_action()
    expected_event = Revision.discontinue_contact_investigation_event()

    assert %{
             author_id: ^user_id,
             reason_action: ^expected_action,
             reason_event: ^expected_event
           } = recent_audit_log(contact_investigation)
  end

  test "discontinuing an interview requires a reason", %{conn: conn, contact_investigation: contact_investigation} do
    view =
      Pages.ContactInvestigationDiscontinue.visit(conn, contact_investigation)
      |> Pages.submit_live("#contact-investigation-discontinue-form", contact_investigation: %{"interview_discontinue_reason" => ""})
      |> Pages.ContactInvestigationDiscontinue.assert_here(contact_investigation)

    view |> Pages.assert_validation_messages(%{"contact_investigation[interview_discontinue_reason]" => "can't be blank"})
  end

  test "warns you that there are changes if you try to navigate away", %{conn: conn, contact_investigation: contact_investigation} do
    view =
      Pages.ContactInvestigationDiscontinue.visit(conn, contact_investigation)
      |> Pages.refute_confirmation_prompt_active()
      |> Pages.ContactInvestigationDiscontinue.change_form(
        contact_investigation: %{"interview_discontinue_reason" => "Transferred to another jurisdiction"}
      )

    assert %{
             "contact_investigation[interview_discontinue_reason]" => "Transferred to another jurisdiction"
           } = Pages.form_state(view)

    view |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")
  end

  test "editing discontinuation reason has a different title", %{conn: conn, contact_investigation: contact_investigation, user: user} do
    {:ok, _} =
      contact_investigation
      |> ContactInvestigations.update({%{interview_discontinued_at: ~U[2020-01-01 12:00:00Z]}, Test.Fixtures.audit_meta(user)})

    view = Pages.ContactInvestigationDiscontinue.visit(conn, contact_investigation)

    assert Pages.ContactInvestigationDiscontinue.form_title(view) == "Edit discontinue interview"
  end

  defp create_contact_investigation(user) do
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
      {Test.Fixtures.contact_investigation_attrs("contact_investigation", %{exposing_case_id: case_investigation.id}),
       Test.Fixtures.admin_audit_meta()}
      |> ContactInvestigations.create()

    contact_investigation
  end
end
