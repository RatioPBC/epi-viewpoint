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

      place_1 = Test.Fixtures.place_attrs(@admin, "place-1") |> Cases.create_place!()

      Test.Fixtures.place_address_attrs(@admin, place_1, "place-address-1", 1111)
      |> Cases.create_place_address!()

      place_2 = Test.Fixtures.place_attrs(@admin, "place-2") |> Cases.create_place!()

      Test.Fixtures.place_address_attrs(@admin, place_2, "place-address-2", 2222)
      |> Cases.create_place_address!()

      [case_investigation: case_investigation]
    end

    test "showing a typeahead result", %{conn: conn, case_investigation: case_investigation} do
      Pages.PlaceSearch.visit(conn, case_investigation)
      |> Pages.PlaceSearch.assert_here(case_investigation)
      |> Pages.PlaceSearch.assert_selectable_results([])
      |> Pages.PlaceSearch.type_in_the_search_box("11")
      |> Pages.PlaceSearch.assert_selectable_results(["1111 Test St, City, OH 00000", "2222 Test St, City, OH 00000"])
    end
  end
end
