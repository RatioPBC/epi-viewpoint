defmodule EpicenterWeb.PlaceLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  describe "creating a place" do
    test "user can create a new place", %{user: user, conn: conn} do
      Pages.Place.visit(conn)
      |> Pages.Place.assert_here()
      |> Pages.Place.submit_place(conn,
        name: "Alicecorp HQ",
        contact_name: "Alice Testuser",
        contact_phone: "111-111-1234",
        contact_email: "alice@example.com",
        type: "workplace"
      )

      #     |> Pages.Profile.assert_here()
      #     |> Pages.Visit.submit_visit(~D[2020-01-01])
      #     |> Pages.Profile.assert_here()
      # todo: place: need address fields, plus contact_name, contact_phone, contact_email
      # todo: visit: need case_investigation or person, and relationship_to_place

      [new_place] = Cases.list_places(user)
      # [new_visit] = Cases.list_visits()

      assert new_place.name == "Alicecorp HQ"
      assert new_place.type == "workplace"
      assert new_place.contact_name == "Alice Testuser"
      assert new_place.contact_phone == "1111111234"
      assert new_place.contact_email == "alice@example.com"
      # assert new_visit.occurred_on == ~D[2020-01-01]
      # assert new_visit.place.id == new_place.id
    end

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
