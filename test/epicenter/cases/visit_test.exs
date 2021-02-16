defmodule Epicenter.Cases.VisitTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.Place
  alias Epicenter.Cases.Visit
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.Visit,
        [
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:place_id, :binary_id},
          {:seq, :integer},
          {:tid, :string},
          {:updated_at, :utc_datetime},
          {:occurred_on, :date}
        ]
      )
    end
  end

  setup :persist_admin
  @admin Test.Fixtures.admin()
  describe "changeset" do
    setup do
      place = Test.Fixtures.place_attrs(@admin, "place") |> Cases.create_place!()
      [place: place]
    end

    defp new_changeset(place, attr_updates \\ %{}) do
      {default_attrs, _audit_meta} = Test.Fixtures.visit_attrs(@admin, "visit", place)
      Visit.changeset(%Visit{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes", %{place: place} do
      changes = new_changeset(place).changes
      assert changes.place_id == place.id
    end

    test "default test attrs are valid", %{place: place} do
      assert_valid(new_changeset(place))
    end

    test "place is required" do
      assert_invalid(new_changeset(%Place{id: nil}))
    end
  end
end
