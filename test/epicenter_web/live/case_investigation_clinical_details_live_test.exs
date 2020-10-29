defmodule EpicenterWeb.CaseInvestigationClinicalDetailsLiveTest do
  use EpicenterWeb.ConnCase, async: true

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

  test "has a case investigation view", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationClinicalDetails.visit(conn, case_investigation)
    |> Pages.CaseInvestigationClinicalDetails.assert_here()
  end
end
