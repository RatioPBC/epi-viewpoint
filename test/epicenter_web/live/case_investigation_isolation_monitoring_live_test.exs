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
        interview_completed_at: ~N[2020-01-01 23:03:07],
        interview_started_at: ~N[2020-01-01 22:03:07],
        symptom_onset_on: ~D[2020-11-03]
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
    {:ok, _} = Cases.update_case_investigation(case_investigation, {%{symptom_onset_on: nil}, Test.Fixtures.admin_audit_meta()})

    Pages.CaseInvestigationIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.CaseInvestigationIsolationMonitoring.assert_here()
    |> Pages.CaseInvestigationIsolationMonitoring.assert_isolation_date_started(
      "10/27/2020",
      "Onset date: Unavailable\n\nPositive lab sample: 10/27/2020"
    )
    |> Pages.CaseInvestigationIsolationMonitoring.assert_isolation_date_ended("11/06/2020")
  end

  test "prefills with saved isolation monitoring dates", %{conn: conn, case_investigation: case_investigation} do
    {:ok, _} =
      Cases.update_case_investigation(
        case_investigation,
        {%{isolation_monitoring_starts_on: ~D[2020-11-01], isolation_monitoring_ends_on: ~D[2020-11-11]}, Test.Fixtures.admin_audit_meta()}
      )

    Pages.CaseInvestigationIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.CaseInvestigationIsolationMonitoring.assert_here()
    |> Pages.CaseInvestigationIsolationMonitoring.assert_isolation_date_started(
      "11/01/2020",
      "Onset date: 11/03/2020\n\nPositive lab sample: 10/27/2020"
    )
    |> Pages.CaseInvestigationIsolationMonitoring.assert_isolation_date_ended("11/11/2020")
  end

  test "saving isolation monitoring dates for a case investigation", %{conn: conn, case_investigation: case_investigation, person: person, user: user} do
    Pages.CaseInvestigationIsolationMonitoring.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-isolation-monitoring-form",
      isolation_monitoring_form: %{
        "date_started" => "08/01/2020",
        "date_ended" => "08/11/2020"
      }
    )
    |> Pages.Profile.assert_here(person)

    assert_recent_audit_log(case_investigation, user, action: "update-case-investigation", event: "edit-case-investigation-isolation-monitoring")
    case_investigation = Cases.get_case_investigation(case_investigation.id)
    assert ~D[2020-08-01] == case_investigation.isolation_monitoring_starts_on
    assert ~D[2020-08-11] == case_investigation.isolation_monitoring_ends_on
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

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, case_investigation: case_investigation} do
      assert Pages.CaseInvestigationIsolationMonitoring.visit(conn, case_investigation)
             |> Pages.navigation_confirmation_prompt()
             |> Euclid.Exists.blank?()
    end

    test "when the user changes something", %{conn: conn, case_investigation: case_investigation} do
      assert "Your updates have not been saved. Discard updates?" =
               Pages.CaseInvestigationIsolationMonitoring.visit(conn, case_investigation)
               |> Pages.CaseInvestigationIsolationMonitoring.change_form(isolation_monitoring_form: %{"date_ended" => "09/06/2020"})
               |> Pages.navigation_confirmation_prompt()
    end
  end
end
