defmodule EpicenterWeb.ContactInvestigationDiscontinueLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    [exposure: create_exposure(user)]
  end

  test "has a working initial render", %{conn: conn, exposure: exposure} do
    {:ok, page_live, disconnected_html} = live(conn, "/contact-investigations/#{exposure.id}/discontinue")

    assert_has_role(disconnected_html, "contact-investigation-discontinue-page")
    assert_has_role(page_live, "contact-investigation-discontinue-page")
  end

  test "initial values", %{conn: conn, exposure: exposure} do
    view = Pages.ContactInvestigationDiscontinue.visit(conn, exposure)

    assert %{
             "exposure[interview_discontinue_reason]" => ""
           } = Pages.form_state(view)

    assert Pages.form_labels(view) == %{
             "exposure[interview_discontinue_reason]" => [
               "Other",
               "Deceased",
               "Transferred to another jurisdiction",
               "Another contact investigation already underway",
               "Unable to reach"
             ]
           }
  end

  test "allows the user to set a discontinuation reason and saves a timestamp of when that happened", %{conn: conn, exposure: exposure, user: user} do
    Pages.ContactInvestigationDiscontinue.visit(conn, exposure)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-discontinue-form",
      exposure: %{"interview_discontinue_reason" => "Unable to reach"}
    )
    |> Pages.Profile.assert_here(exposure.exposed_person)

    updated_contact_investigation = Cases.get_exposure(exposure.id)
    assert "Unable to reach" = updated_contact_investigation.interview_discontinue_reason
    assert_datetime_approximate(updated_contact_investigation.interview_discontinued_at, DateTime.utc_now(), 2)

    user_id = user.id
    expected_action = Revision.update_exposure_action()
    expected_event = Revision.discontinue_contact_investigation_event()

    assert %{
             author_id: ^user_id,
             reason_action: ^expected_action,
             reason_event: ^expected_event
           } = recent_audit_log(exposure)
  end

  test "discontinuing an interview requires a reason", %{conn: conn, exposure: exposure} do
    view =
      Pages.ContactInvestigationDiscontinue.visit(conn, exposure)
      |> Pages.submit_live("#contact-investigation-discontinue-form", exposure: %{"interview_discontinue_reason" => ""})
      |> Pages.ContactInvestigationDiscontinue.assert_here(exposure)

    view |> Pages.assert_validation_messages(%{"exposure[interview_discontinue_reason]" => "can't be blank"})
  end

  defp create_exposure(user) do
    sick_person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Cases.create_person!()

    lab_result =
      Test.Fixtures.lab_result_attrs(sick_person, user, "lab_result", ~D[2020-08-07])
      |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(sick_person, lab_result, user, "the contagious person's case investigation")
      |> Cases.create_case_investigation!()

    {:ok, exposure} =
      {Test.Fixtures.case_investigation_exposure_attrs(case_investigation, "exposure"), Test.Fixtures.admin_audit_meta()}
      |> Cases.create_exposure()

    exposure
  end
end
