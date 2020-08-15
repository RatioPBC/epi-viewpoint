defmodule Epicenter.Cases.PersonTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Person,
        [
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:first_name, :string},
          {:last_name, :string},
          {:dob, :date},
          {:tid, :string},
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      default_attrs = Test.Fixtures.person_attrs("alice", "06-01-2020")
      Cases.change_person(%Person{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "dib is required", do: assert_invalid(new_changeset(dob: nil))
    test "first name is required", do: assert_invalid(new_changeset(first_name: nil))
    test "last name is required", do: assert_invalid(new_changeset(last_name: nil))
  end
end
