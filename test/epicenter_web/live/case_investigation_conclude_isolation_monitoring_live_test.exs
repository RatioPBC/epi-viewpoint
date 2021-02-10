defmodule EpicenterWeb.CaseInvestigationConcludeIsolationMonitoringLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "investigation", %{
        interview_completed_at: ~N[2020-10-31 23:03:07],
        interview_started_at: ~N[2020-10-31 22:03:07],
        isolation_monitoring_ends_on: ~D[2020-11-13],
        isolation_monitoring_starts_on: ~D[2020-11-03]
      })
      |> Cases.create_case_investigation!()

    [case_investigation: case_investigation, person: person, user: user]
  end

  test "records an audit log entry", %{conn: conn, case_investigation: case_investigation, user: user} do
    case_investigation = case_investigation |> Cases.preload_person()

    AuditLogAssertions.expect_phi_view_logs(22)
    Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
    AuditLogAssertions.verify_phi_view_logged(user, case_investigation.person)
  end

  test "shows conclude isolation monitoring form", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.CaseInvestigationConcludeIsolationMonitoring.assert_here()
    |> Pages.CaseInvestigationConcludeIsolationMonitoring.assert_page_heading("Conclude isolation monitoring")
    |> Pages.CaseInvestigationConcludeIsolationMonitoring.assert_reasons_selection(%{
      "Successfully completed isolation period" => false,
      "Person unable to isolate" => false,
      "Refused to cooperate" => false,
      "Lost to follow up" => false,
      "Transferred to another jurisdiction" => false,
      "Deceased" => false
    })
  end

  test "prefills the form if there is already a reason on the case investigation", %{conn: conn, case_investigation: case_investigation} do
    {:ok, _} =
      Cases.update_case_investigation(
        case_investigation,
        {%{isolation_conclusion_reason: "successfully_completed", isolation_concluded_at: ~U[2020-10-31 10:30:00Z]}, Test.Fixtures.admin_audit_meta()}
      )

    Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.CaseInvestigationConcludeIsolationMonitoring.assert_here()
    |> Pages.CaseInvestigationConcludeIsolationMonitoring.assert_page_heading("Edit conclude isolation monitoring")
    |> Pages.CaseInvestigationConcludeIsolationMonitoring.assert_reasons_selection(%{
      "Successfully completed isolation period" => true,
      "Person unable to isolate" => false,
      "Refused to cooperate" => false,
      "Lost to follow up" => false,
      "Transferred to another jurisdiction" => false,
      "Deceased" => false
    })
  end

  test "saving isolation conclusion reason for a case investigation", %{
    conn: conn,
    case_investigation: case_investigation,
    person: person,
    user: user
  } do
    Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-conclude-isolation-monitoring-form",
      conclude_isolation_monitoring_form: %{
        "reason" => "successfully_completed"
      }
    )
    |> Pages.Profile.assert_here(person)

    assert_recent_audit_log(case_investigation, user, action: "update-case-investigation", event: "conclude-case-investigation-isolation-monitoring")
    case_investigation = Cases.get_case_investigation(case_investigation.id, user)
    assert "successfully_completed" == case_investigation.isolation_conclusion_reason
    assert ~U[2020-10-31 10:30:00Z] == case_investigation.isolation_concluded_at
  end

  test "editing an isolation conclusion reason does not change the existing isolation_concluded_at timestamp", %{
    conn: conn,
    case_investigation: case_investigation,
    person: person,
    user: user
  } do
    {:ok, _} =
      Cases.update_case_investigation(
        case_investigation,
        {%{isolation_conclusion_reason: "successfully_completed", isolation_concluded_at: ~U[2020-10-05 19:57:00Z]}, Test.Fixtures.admin_audit_meta()}
      )

    Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-conclude-isolation-monitoring-form",
      conclude_isolation_monitoring_form: %{
        "reason" => "deceased"
      }
    )
    |> Pages.Profile.assert_here(person)

    assert_recent_audit_log(case_investigation, user, action: "update-case-investigation", event: "conclude-case-investigation-isolation-monitoring")
    case_investigation = Cases.get_case_investigation(case_investigation.id, user)
    assert "deceased" == case_investigation.isolation_conclusion_reason
    assert ~U[2020-10-05 19:57:00Z] == case_investigation.isolation_concluded_at
  end

  describe "validations" do
    test "saving without a selected reason shows an error", %{
      conn: conn,
      case_investigation: case_investigation
    } do
      Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
      |> Pages.submit_live("#case-investigation-conclude-isolation-monitoring-form", conclude_isolation_monitoring_form: %{})
      |> Pages.assert_validation_messages(%{
        "conclude_isolation_monitoring_form[reason]" => "can't be blank"
      })

      assert_revision_count(case_investigation, 1)
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes something", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
        |> Pages.CaseInvestigationConcludeIsolationMonitoring.change_form(conclude_isolation_monitoring_form: %{"reason" => "deceased"})
        |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")

      assert %{"conclude_isolation_monitoring_form[reason]" => "deceased"} = Pages.form_state(view)
    end
  end
end
