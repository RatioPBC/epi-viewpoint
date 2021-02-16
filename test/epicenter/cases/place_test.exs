defmodule Epicenter.Cases.PlaceTest do
  use Epicenter.DataCase, async: true

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
      changes = new_changeset(name: "444 Elementary", type: "school").changes
      assert changes.name == "444 Elementary"
      assert changes.type == "school"
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
  end
end
