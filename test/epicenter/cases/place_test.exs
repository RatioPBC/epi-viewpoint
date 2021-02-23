defmodule Epicenter.Cases.PlaceTest do
  use Epicenter.DataCase, async: true

  alias Ecto.Multi
  alias Epicenter.Cases
  alias Epicenter.Cases.Place
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Place,
        [
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:name, :string},
          {:seq, :integer},
          {:tid, :string},
          {:type, :string},
          {:contact_name, :string},
          {:contact_phone, :string},
          {:contact_email, :string},
          {:updated_at, :utc_datetime}
        ]
      )
    end
  end

  setup :persist_admin
  @admin Test.Fixtures.admin()
  describe "changeset" do
    defp new_changeset(attr_updates) do
      {default_attrs, _} = Test.Fixtures.place_attrs(@admin, "place")

      Place.changeset(%Place{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      changes =
        new_changeset(
          name: "444 Elementary",
          type: "school",
          contact_name: "Alice Testuser",
          contact_phone: "111-111-1234",
          contact_email: "test@example.com"
        ).changes

      assert changes.name == "444 Elementary"
      assert changes.type == "school"
      assert changes.contact_name == "Alice Testuser"
      assert changes.contact_phone == "1111111234"
      assert changes.contact_email == "test@example.com"
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))

    test "validates name doesn't contain pii in non-prod", do: assert_invalid(new_changeset(contact_name: "Alice"))
    test "validates phone doesn't contain pii in non-prod", do: assert_invalid(new_changeset(contact_phone: "323-555-1234"))
    test "validates email doesn't contain pii in non-prod", do: assert_invalid(new_changeset(contact_email: "test@google.com"))
  end

  describe "associations" do
    test "has one place_address" do
      place = Test.Fixtures.place_attrs(@admin, "place") |> Cases.create_place!()
      Test.Fixtures.place_address_attrs(@admin, place, "place-address", 3456) |> Cases.create_place_address!()

      place = place |> Cases.preload_place_address()

      assert place.place_address.tid == "place-address"
    end
  end

  describe "multi_for_insert" do
    test "when there are place_address_attrs, it includes an insert for place_addresses" do
      place_attrs = %{name: "123 Elementary", type: "school"}
      place_address_attrs = %{street: "1234 Test St"}

      multi_keys = Place.multi_for_insert(place_attrs, place_address_attrs) |> Multi.to_list() |> Keyword.keys()
      assert multi_keys == [:place, :place_address]
    end

    test "when there place_address_attrs is nil, it only does the place insert" do
      place_attrs = %{name: "123 Elementary", type: "school"}

      multi_keys = Place.multi_for_insert(place_attrs, nil) |> Multi.to_list() |> Keyword.keys()
      assert multi_keys == [:place]
    end
  end
end
