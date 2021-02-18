defmodule EpicenterWeb.PlaceSearchLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user
  @admin Test.Fixtures.admin()

  describe "The place search page" do
    setup %{user: user} do
      person = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", ~D[2020-10-27]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "case-investigation")
        |> Cases.create_case_investigation!()

      [case_investigation: case_investigation]
    end

    test "navigating", %{conn: conn, case_investigation: case_investigation} do
      Pages.PlaceSearch.visit(conn, case_investigation)
      |> Pages.PlaceSearch.assert_here(case_investigation)
    end
  end
end
