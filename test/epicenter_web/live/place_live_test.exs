defmodule EpicenterWeb.PlaceLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  @tag :skip
  describe "creating a place" do
    test "user can create a new place", %{conn: conn} do
      Pages.Place.visit(conn)
      |> Pages.Place.assert_here()
      |> Pages.Place.submit_place(name: "Alicecorp HQ", type: "Workplace")
      |> Pages.Visit.assert_here()
      |> Pages.Visit.submit_visit(~D[2020-01-01])

      # todo: place: need address fields, plus contact_name, contact_phone, contact_email
      # todo: visit: need case_investigation or person, and relationship_to_place

      [new_place] = Cases.list_places()
      [new_visit] = Cases.list_visits()

      assert new_visit.occurred_on == ~D[2020-01-01]
      assert new_visit.place.id == new_place.id
      assert new_place.name == "Alicecorp HQ"
      assert new_place.type == "Workplace"
    end
  end
end
