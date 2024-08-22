defmodule EpiViewpoint.Cases.Place.SearchTest do
  use EpiViewpoint.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Place
  alias EpiViewpoint.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  defp create_place(tid, street_number, attrs \\ %{}) do
    place = Test.Fixtures.place_attrs(@admin, "#{tid}-place", attrs) |> Cases.create_place!()

    Test.Fixtures.place_address_attrs(@admin, place, "#{tid}-place-address", street_number)
    |> Cases.create_place_address!()

    :ok
  end

  describe "Cases.search_places context delegation" do
    def search_via_context(term) do
      Cases.search_places(term) |> tids()
    end

    test "finds places" do
      create_place("hospital", 1111)
      assert search_via_context("1111") == ~w[hospital-place-address]
    end

    # TODO audit log? Places are less sensitive than individual's addresses?
  end

  describe "find" do
    def search(term) do
      Place.Search.find(term) |> tids()
    end

    test "empty string returns empty results" do
      assert search("") == []
      assert search("   ") == []
    end

    test "finds places with matching name, case-insensitive" do
      create_place("matched", 1234, %{name: "Matching Name"})
      create_place("unmatched", 1234, %{name: "Unmatched Name"})

      assert search("matching") == ["matched-place-address"]
    end

    test "finds places whose street address matches" do
      create_place("matched", 1234)
      create_place("unmatched", 3456)

      assert search("1234") == ["matched-place-address"]
    end

    test "returns multiple results when appropriate" do
      create_place("matched-address", 1234)
      create_place("matched-name", 3456, %{name: "1234 fitness"})

      assert search("1234") == ["matched-address-place-address", "matched-name-place-address"]
    end
  end
end
