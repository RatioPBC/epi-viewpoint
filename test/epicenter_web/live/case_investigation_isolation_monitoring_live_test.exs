defmodule EpicenterWeb.CaseInvestigationIsolationMonitoringLiveTest do
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
        completed_interview_at: ~N[2020-01-01 23:03:07],
        symptom_onset_date: ~D[2020-11-03]
      })
      |> Cases.create_case_investigation!()

    [case_investigation: case_investigation, person: person, user: user]
  end

  test "shows isolation monitoring form", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.CaseInvestigationIsolationMonitoring.assert_here()
  end

  test "prefills date started with symptom onset date if present", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.CaseInvestigationIsolationMonitoring.assert_here()
    |> Pages.CaseInvestigationIsolationMonitoring.assert_isolation_date_started(
      "11/03/2020",
      "Onset date: 11/03/2020\n\nPositive lab sample: 10/27/2020"
    )
    |> Pages.CaseInvestigationIsolationMonitoring.assert_isolation_date_ended("11/13/2020")
  end

  test "prefills date started with lab collection date when symptom onset date is not present", %{conn: conn, case_investigation: case_investigation} do
    {:ok, _} = Cases.update_case_investigation(case_investigation, {%{symptom_onset_date: nil}, Test.Fixtures.admin_audit_meta()})

    Pages.CaseInvestigationIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.CaseInvestigationIsolationMonitoring.assert_here()
    |> Pages.CaseInvestigationIsolationMonitoring.assert_isolation_date_started(
      "10/27/2020",
      "Onset date: Unavailable\n\nPositive lab sample: 10/27/2020"
    )
    |> Pages.CaseInvestigationIsolationMonitoring.assert_isolation_date_ended("11/06/2020")
  end

  describe "validations" do
    test "shows the errors for invalid dates", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationIsolationMonitoring.visit(conn, case_investigation)
      |> Pages.submit_live("#case-investigation-isolation-monitoring-form",
        isolation_monitoring_form: %{
          "date_started" => "02/31/2020",
          "date_ended" => "09/32/2020"
        }
      )
      |> Pages.assert_validation_messages(%{
        "isolation_monitoring_form_date_started" => "must be a valid MM/DD/YYYY date",
        "isolation_monitoring_form_date_ended" => "must be a valid MM/DD/YYYY date"
      })
    end
  end
end
