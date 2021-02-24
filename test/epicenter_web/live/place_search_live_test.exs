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

      place_1 = Test.Fixtures.place_attrs(@admin, "place-1", %{name: "Alice's Donuts"}) |> Cases.create_place!()

      place_address_1 =
        Test.Fixtures.place_address_attrs(@admin, place_1, "place-address-1", 1111)
        |> Cases.create_place_address!()

      place_2 = Test.Fixtures.place_attrs(@admin, "place-2", %{name: "David's Donuts"}) |> Cases.create_place!()

      place_address_2 =
        Test.Fixtures.place_address_attrs(@admin, place_2, "place-address-2", 1122)
        |> Cases.create_place_address!()

      [case_investigation: case_investigation, place_address_1: place_address_1, place_address_2: place_address_2]
    end

    test "showing a typeahead result", %{conn: conn, case_investigation: case_investigation} do
      Pages.PlaceSearch.visit(conn, case_investigation)
      |> Pages.PlaceSearch.assert_here(case_investigation)
      |> Pages.PlaceSearch.assert_selectable_results([])
      |> Pages.PlaceSearch.type_in_the_search_box("11")
      |> Pages.PlaceSearch.assert_selectable_results([
        "Alice's Donuts1111 Test St, City, OH 00000",
        "David's Donuts1122 Test St, City, OH 00000"
      ])
    end

    test "clicking a typeahead result", %{conn: conn, case_investigation: case_investigation, place_address_1: place_address_1} do
      Pages.PlaceSearch.visit(conn, case_investigation)
      |> Pages.PlaceSearch.type_in_the_search_box("11")
      |> Pages.PlaceSearch.assert_selectable_results([
        "Alice's Donuts1111 Test St, City, OH 00000",
        "David's Donuts1122 Test St, City, OH 00000"
      ])
      |> Pages.PlaceSearch.click_result_and_follow_redirect(conn, "place-address-1")
      |> Pages.AddVisit.assert_here(case_investigation, place_address_1)
    end

    test "only matching results show up", %{conn: conn, case_investigation: case_investigation} do
      Pages.PlaceSearch.visit(conn, case_investigation)
      |> Pages.PlaceSearch.type_in_the_search_box("Alice's Donuts")
      |> Pages.PlaceSearch.assert_selectable_results(["Alice's Donuts1111 Test St, City, OH 00000"])
    end

    test "navigating to create a new  place", %{conn: conn, case_investigation: case_investigation} do
      Pages.PlaceSearch.visit(conn, case_investigation)
      |> Pages.PlaceSearch.click_add_new_place_and_follow_redirect(conn)
      |> Pages.Place.assert_here(case_investigation)
    end
  end
end
