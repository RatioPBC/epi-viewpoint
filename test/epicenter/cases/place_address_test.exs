defmodule Epicenter.Cases.PlaceAddressTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.PlaceAddress
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.PlaceAddress,
        [
          {:address_fingerprint, :string},
          {:city, :string},
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:place_id, :binary_id},
          {:postal_code, :string},
          {:seq, :integer},
          {:state, :string},
          {:street, :string},
          {:tid, :string},
          {:updated_at, :utc_datetime}
        ]
      )
    end
  end

  setup :persist_admin
  @admin Test.Fixtures.admin()
  describe "changeset" do
    defp new_changeset(attr_updates, place \\ nil) do
      place =
        if place == nil do
          Test.Fixtures.place_attrs(@admin, "place") |> Cases.create_place!()
        else
          place
        end

      {default_attrs, _} = Test.Fixtures.place_address_attrs(@admin, place, "school-address", 1234, %{})

      PlaceAddress.changeset(%PlaceAddress{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      place = Test.Fixtures.place_attrs(@admin, "place") |> Cases.create_place!()
      changes = new_changeset([], place).changes
      assert changes.street == "1234 Test St"
      assert changes.city == "City"
      assert changes.state == "OH"
      assert changes.postal_code == "00000"
      assert changes.tid == "school-address"
      assert changes.place_id == place.id
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "street is optional", do: assert_valid(new_changeset(street: nil))
    test "city is optional", do: assert_valid(new_changeset(city: nil))
    test "state is optional", do: assert_valid(new_changeset(state: nil))
    test "postal_code is optional", do: assert_valid(new_changeset(postal_code: nil))

    test "validates personal health information on address", do: assert_invalid(new_changeset(street: "123 main st"))
  end

  describe "to_comparable_string" do
    test "returns a string that's meant for comparison" do
      %PlaceAddress{street: "1000  Test st", city: "   City3  ", state: "Al", postal_code: " 00001 "}
      |> PlaceAddress.to_comparable_string()
      |> assert_eq("1000 test st city3 al 00001")
    end

    test "handles missing fields" do
      %PlaceAddress{street: "1000  Test st", city: nil, state: "Al", postal_code: " 00001 "}
      |> PlaceAddress.to_comparable_string()
      |> assert_eq("1000 test st al 00001")
    end
  end
end
