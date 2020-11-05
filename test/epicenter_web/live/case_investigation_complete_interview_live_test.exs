defmodule EpicenterWeb.CaseInvestigationCompleteInterviewLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
    case_investigation = Test.Fixtures.case_investigation_attrs(person, lab_result, user, "investigation") |> Cases.create_case_investigation!()
    [case_investigation: case_investigation, person: person, user: user]
  end

  test "shows complete case investigation form", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationCompleteInterview.visit(conn, case_investigation)
    |> Pages.CaseInvestigationCompleteInterview.assert_here()
    |> Pages.CaseInvestigationCompleteInterview.assert_date_completed(:today)
    |> Pages.CaseInvestigationCompleteInterview.assert_time_completed(:now)
  end

  test "prefills with existing data when existing data is available", %{conn: conn, case_investigation: case_investigation} do
    {:ok, _} =
      Cases.update_case_investigation(
        case_investigation,
        {%{completed_interview_at: ~N[2020-01-01 23:03:07]}, Test.Fixtures.admin_audit_meta()}
      )

    Pages.CaseInvestigationCompleteInterview.visit(conn, case_investigation)
    |> Pages.CaseInvestigationCompleteInterview.assert_here()
    |> Pages.CaseInvestigationCompleteInterview.assert_time_completed("06:03", "PM")
    |> Pages.CaseInvestigationCompleteInterview.assert_date_completed("01/01/2020")
  end
end