defmodule EpicenterWeb.PlaceLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  describe "creating a place" do
    setup %{user: user} do
      person = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab-result", ~D[2000-01-01]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, user, "case-investigation") |> Cases.create_case_investigation!()

      [case_investigation: case_investigation]
    end

    test "user can create a new place with an address and is sent to the new visit page", %{
      user: user,
      conn: conn,
      case_investigation: case_investigation
    } do
      view =
        Pages.Place.visit(conn, case_investigation)
        |> Pages.Place.assert_here(case_investigation)
        |> Pages.Place.submit_place(conn,
          name: "Alicecorp HQ",
          street: "1234 Test St",
          street_2: "Unit 303",
          city: "City",
          state: "OH",
          postal_code: "00000",
          contact_name: "Alice Testuser",
          contact_phone: "111-111-1234",
          contact_email: "alice@example.com",
          type: "workplace"
        )

      [place_address] = Cases.list_place_addresses()
      view |> Pages.AddVisit.assert_here(case_investigation, place_address)

      [new_place] = Cases.list_places(user) |> Cases.preload_place_addresses()

      assert new_place.name == "Alicecorp HQ"
      assert new_place.type == "workplace"
      assert new_place.contact_name == "Alice Testuser"
      assert new_place.contact_phone == "1111111234"
      assert new_place.contact_email == "alice@example.com"

      [place_address] = new_place.place_addresses
      assert place_address.street == "1234 Test St"
      assert place_address.street_2 == "Unit 303"
      assert place_address.city == "City"
      assert place_address.state == "OH"
      assert place_address.postal_code == "00000"
    end

    test "user can create a new place without an address", %{user: user, conn: conn, case_investigation: case_investigation} do
      Pages.Place.visit(conn, case_investigation)
      |> Pages.Place.assert_here(case_investigation)
      |> Pages.Place.submit_place(conn,
        name: "Alicecorp HQ",
        type: "workplace"
      )

      [new_place] = Cases.list_places(user) |> Cases.preload_place_addresses()

      assert new_place.name == "Alicecorp HQ"
      assert new_place.type == "workplace"
    end

    test "shows errors when creating invalid place", %{conn: conn, case_investigation: case_investigation} do
      Pages.Place.visit(conn, case_investigation)
      |> Pages.Place.assert_here(case_investigation)
      |> Pages.submit_live("#place-form",
        place_form: %{
          "city" => "glorp",
          "contact_email" => "alice@google.com",
          "contact_name" => "Alice Invalid",
          "contact_phone" => "123-456-7890",
          "name" => "Alice HQ",
          "postal_code" => "12345",
          "state" => "AL",
          "street" => "1234 Unsafe St",
          "street_2" => "Anything",
          "type" => "workplace"
        }
      )
      |> Pages.assert_validation_messages(%{
        "place_form[contact_name]" => "In non-PHI environment, must contain 'Testuser'",
        "place_form[city]" => "In non-PHI environment, must match 'City#'",
        "place_form[contact_email]" => "In non-PHI environment, must end with '@example.com'",
        "place_form[contact_phone]" => "In non-PHI environment, must match '111-111-1xxx'",
        "place_form[postal_code]" => "In non-PHI environment, must match '0000x'",
        "place_form[street]" => "In non-PHI environment, must match '#### Test St'"
      })
    end

    @tag :skip
    test "back button goes back to profile page"
  end
end
