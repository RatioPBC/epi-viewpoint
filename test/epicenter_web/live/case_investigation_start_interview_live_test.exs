defmodule EpicenterWeb.CaseInvestigationStartInterviewLiveTest do
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

  test "shows start case investigation form", %{conn: conn, person: person, case_investigation: case_investigation} do
    Pages.CaseInvestigationStartInterview.visit(conn, person, case_investigation)
    |> Pages.CaseInvestigationStartInterview.assert_here()
    |> Pages.CaseInvestigationStartInterview.assert_person_interviewed_selections(%{"Alice Testuser" => false, "Proxy" => false})
    |> Pages.CaseInvestigationStartInterview.assert_date_started(:today)
    |> Pages.CaseInvestigationStartInterview.assert_time_started(:now)
  end

  test "saving start case investigation form", %{conn: conn, person: person, case_investigation: case_investigation} do
    Pages.CaseInvestigationStartInterview.visit(conn, person, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-interview-start-form",
      start_interview_form: %{
        "person_interviewed" => "Alice's guardian",
        "date_started" => "09/06/2020",
        "time_started" => "03:45",
        "time_started_am_pm" => "PM"
      }
    )
    |> Pages.Profile.assert_here(person)

    case_investigation = Cases.get_case_investigation(case_investigation.id)
    assert "Alice's guardian" = case_investigation.person_interviewed
    #    assert Timex.to_datetime({{2020, 9, 6}, {19, 45, 0}}, "UTC") == case_investigation.started_at
  end
end
