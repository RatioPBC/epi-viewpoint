defmodule EpicenterWeb.CaseInvestigationDiscontinueLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Euclid.Test.Extra.Assertions, only: [assert_datetime_approximate: 2]

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

  test "disconnected and connected render", %{conn: conn, person: person, case_investigation: case_investigation} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}/case_investigations/#{case_investigation.id}/discontinue")

    assert_has_role(disconnected_html, "case-investigation-discontinue-page")
    assert_has_role(page_live, "case-investigation-discontinue-page")
  end

  test "has a reason select radio", %{conn: conn, person: person, case_investigation: case_investigation} do
    Pages.CaseInvestigationDiscontinue.visit(conn, person, case_investigation)
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
    case_investigation: case_investigation
  } do
    Pages.CaseInvestigationDiscontinue.visit(conn, person, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-discontinue-form",
      case_investigation: %{"discontinue_reason" => "Unable to reach"}
    )
    |> Pages.Profile.assert_here(person)

    case_investigation = Cases.get_case_investigation(case_investigation.id)
    assert "Unable to reach" = case_investigation.discontinue_reason
    assert_datetime_approximate(case_investigation.discontinued_at, DateTime.utc_now())
  end
end
