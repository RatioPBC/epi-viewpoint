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
        completed_interview_at: ~N[2020-10-31 23:03:07],
        isolation_monitoring_start_date: ~D[2020-11-03],
        isolation_monitoring_end_date: ~D[2020-11-13]
      })
      |> Cases.create_case_investigation!()

    [case_investigation: case_investigation, person: person, user: user]
  end

  test "shows conclude isolation monitoring form", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.CaseInvestigationConcludeIsolationMonitoring.assert_here()
    |> Pages.CaseInvestigationConcludeIsolationMonitoring.assert_reasons_selection(%{
      "Successfully completed isolation period" => false,
      "Person unable to isolate" => false,
      "Refused to cooperate" => false,
      "Lost to follow up" => false,
      "Transferred to another jurisdiction" => false,
      "Deceased" => false
    })
  end

  #  test "saving isolation monitoring dates for a case investigation", %{conn: conn, case_investigation: case_investigation, person: person, user: user} do
  #    Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
  #    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-isolation-monitoring-form",
  #      isolation_monitoring_form: %{
  #        "date_started" => "08/01/2020",
  #        "date_ended" => "08/11/2020"
  #      }
  #    )
  #    |> Pages.Profile.assert_here(person)
  #
  #    assert_recent_audit_log(case_investigation, user, action: "update-case-investigation", event: "edit-case-investigation-isolation-monitoring")
  #    case_investigation = Cases.get_case_investigation(case_investigation.id)
  #    assert ~D[2020-08-01] == case_investigation.isolation_monitoring_start_date
  #    assert ~D[2020-08-11] == case_investigation.isolation_monitoring_end_date
  #  end
  #
  #  describe "warning the user when navigation will erase their changes" do
  #    test "before the user changes anything", %{conn: conn, case_investigation: case_investigation} do
  #      Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
  #      |> Pages.assert_confirmation_prompt("")
  #    end
  #
  #    test "when the user changes something", %{conn: conn, case_investigation: case_investigation} do
  #      Pages.CaseInvestigationConcludeIsolationMonitoring.visit(conn, case_investigation)
  #      |> Pages.CaseInvestigationConcludeIsolationMonitoring.change_form(isolation_monitoring_form: %{"date_ended" => "09/06/2020"})
  #      |> Pages.assert_confirmation_prompt("Your updates have not been saved. Discard updates?")
  #    end
  #  end
end
