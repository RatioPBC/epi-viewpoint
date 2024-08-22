defmodule EpiViewpointWeb.Presenters.PlacePresenterTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.Test
  alias EpiViewpoint.Cases
  alias EpiViewpointWeb.Presenters.PlacePresenter

  @admin Test.Fixtures.admin()

  describe "address" do
    setup do
      %{
        place: Test.Fixtures.place_attrs(@admin, "place-1", %{name: "the best place"}) |> Cases.create_place!()
      }
    end

    test "renders first address", %{place: place} do
      Test.Fixtures.place_address_attrs(@admin, place, "place-address-1", 1111) |> Cases.create_place_address!()
      Test.Fixtures.place_address_attrs(@admin, place, "place-address-1", 2222) |> Cases.create_place_address!()
      place = Cases.preload_place_addresses(place)

      address = PlacePresenter.address(place)
      assert address =~ "1111"
      refute address =~ "2222"
    end

    test "renders empty string when there are no addresses", %{place: place} do
      place = Cases.preload_place_addresses(place)
      assert PlacePresenter.address(place) == ""
    end
  end
end
