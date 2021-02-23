defmodule EpicenterWeb.PlaceLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  describe "creating a place" do
    test "user can create a new place with an address", %{user: user, conn: conn} do
      Pages.Place.visit(conn)
      |> Pages.Place.assert_here()
      |> Pages.Place.submit_place(conn,
        name: "Alicecorp HQ",
        street: "1234 Test St",
        contact_name: "Alice Testuser",
        contact_phone: "111-111-1234",
        contact_email: "alice@example.com",
        type: "workplace"
      )

      [new_place] = Cases.list_places(user) |> Cases.preload_place_address()

      assert new_place.name == "Alicecorp HQ"
      assert new_place.place_address.street == "1234 Test St"
      assert new_place.type == "workplace"
      assert new_place.contact_name == "Alice Testuser"
      assert new_place.contact_phone == "1111111234"
      assert new_place.contact_email == "alice@example.com"
    end

    test "user can create a new place without an address", %{user: user, conn: conn} do
      Pages.Place.visit(conn)
      |> Pages.Place.assert_here()
      |> Pages.Place.submit_place(conn,
        name: "Alicecorp HQ",
        type: "workplace"
      )

      [new_place] = Cases.list_places(user) |> Cases.preload_place_address()

      assert new_place.name == "Alicecorp HQ"
      assert new_place.type == "workplace"
    end

    @tag :skip
    test "shows errors when creating invalid place", %{conn: conn} do
      Pages.Place.visit(conn)
      |> Pages.Place.assert_here()
      |> Pages.submit_live("#place-form",
        place_form: %{
          "name" => "Alice HQ",
          "contact_name" => "Alice Invalid",
          "contact_phone" => "111-111-1000",
          "contact_email" => "alice@example.com",
          "type" => "workplace"
        }
      )
      |> Pages.assert_validation_messages(%{
        "place[contact_name]" => "In non-PHI environment, must contain 'Testuser'"
      })
    end

    @tag :skip
    test "back button goes back to profile page"
  end
end
