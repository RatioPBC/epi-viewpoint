defmodule EpicenterWeb.CaseInvestigationStartLiveTest do
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

  test "shows start case investigation form", %{conn: conn, person: person} do
    Pages.CaseInvestigationStart.visit(conn, person)
    |> Pages.CaseInvestigationStart.assert_here()
    |> Pages.CaseInvestigationStart.assert_person_interviewed_selections(%{"Alice Testuser" => false, "Proxy" => false})
  end
end
