defmodule EpicenterWeb.CaseInvestigationDiscontinueLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Euclid.Test.Extra.Assertions, only: [assert_datetime_approximate: 3]

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "alice-test-result", ~D[2020-08-06]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "alice-case-investigation") |> Cases.create_case_investigation!()

    [person: person, user: user, case_investigation: case_investigation]
  end

  test "disconnected and connected render", %{conn: conn, case_investigation: case_investigation} do
    {:ok, page_live, disconnected_html} = live(conn, "/case-investigations/#{case_investigation.id}/discontinue")

    assert_has_role(disconnected_html, "case-investigation-discontinue-page")
    assert_has_role(page_live, "case-investigation-discontinue-page")
  end

  test "records an audit log entry", %{conn: conn, case_investigation: case_investigation, user: user} do
    case_investigation = case_investigation |> Cases.preload_person()

    AuditLogAssertions.expect_phi_view_logs(22)
    Pages.CaseInvestigationDiscontinue.visit(conn, case_investigation)
    AuditLogAssertions.verify_phi_view_logged(user, case_investigation.person)
  end

  test "has a reason select radio", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationDiscontinue.visit(conn, case_investigation)
    |> Pages.CaseInvestigationDiscontinue.assert_here()
    |> Pages.CaseInvestigationDiscontinue.assert_reason_selections(%{
      "Unable to reach" => false,
      "Transferred to another jurisdiction" => false,
      "Deceased" => false,
      "Other" => false
    })
  end

  test "marks the case_investigation as discontinued with the given reason at now", %{
    conn: conn,
    person: person,
    case_investigation: case_investigation,
    user: user
  } do
    Pages.CaseInvestigationDiscontinue.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-discontinue-form",
      case_investigation: %{"interview_discontinue_reason" => "Unable to reach"}
    )
    |> Pages.Profile.assert_here(person)

    case_investigation = Cases.get_case_investigation(case_investigation.id, user)
    assert "Unable to reach" = case_investigation.interview_discontinue_reason
    assert_datetime_approximate(case_investigation.interview_discontinued_at, DateTime.utc_now(), 2)
  end

  test "reasons for discontinuing are different between case investigation that have started and those that have not", %{
    conn: conn,
    case_investigation: case_investigation
  } do
    view = Pages.CaseInvestigationDiscontinue.visit(conn, case_investigation)
    assert preset_reasons(view) == ["Deceased", "Transferred to another jurisdiction", "Unable to reach"]

    {:ok, case_investigation} =
      Cases.update_case_investigation(case_investigation, {%{interview_started_at: NaiveDateTime.utc_now()}, Test.Fixtures.admin_audit_meta()})

    view = Pages.CaseInvestigationDiscontinue.visit(conn, case_investigation)

    assert preset_reasons(view) == ["Refused to cooperate", "Lost to follow up", "Transferred to another jurisdiction", "Deceased"]
  end

  defp preset_reasons(view) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.all("[name='case_investigation[interview_discontinue_reason]']", fn element -> Test.Html.attr(element, "value") |> List.first() end)
    |> Enum.reject(&Euclid.Exists.blank?/1)
  end

  test "discontinuing requires a reason", %{conn: conn, case_investigation: case_investigation} do
    view =
      Pages.CaseInvestigationDiscontinue.visit(conn, case_investigation)
      |> Pages.submit_live("#case-investigation-discontinue-form", case_investigation: %{"interview_discontinue_reason" => ""})
      |> Pages.CaseInvestigationDiscontinue.assert_here()

    view |> render() |> Pages.assert_validation_messages(%{"case_investigation[interview_discontinue_reason]" => "can't be blank"})
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationDiscontinue.visit(conn, case_investigation)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes something", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.CaseInvestigationDiscontinue.visit(conn, case_investigation)
        |> Pages.CaseInvestigationDiscontinue.change_form(case_investigation: %{"interview_discontinue_reason" => "something"})
        |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")

      assert %{"case_investigation[interview_discontinue_reason]" => "something"} = Pages.form_state(view)
    end
  end
end
