defmodule Epicenter.Cases.PersonTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

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

  describe "associations" do
    test "can have zero lab_results" do
      alice = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person!()
      alice |> Cases.preload_lab_results() |> Map.get(:lab_results) |> assert_eq([])
    end

    test "has many lab_results" do
      alice = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, "result1", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, "result2", "06-02-2020") |> Cases.create_lab_result!()

      alice |> Cases.preload_lab_results() |> Map.get(:lab_results) |> tids() |> assert_eq(~w{result1 result2}, ignore_order: true)
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      default_attrs = Test.Fixtures.person_attrs("alice", "01-01-2000")
      Cases.change_person(%Person{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "dib is required", do: assert_invalid(new_changeset(dob: nil))
    test "first name is required", do: assert_invalid(new_changeset(first_name: nil))
    test "last name is required", do: assert_invalid(new_changeset(last_name: nil))
  end
end
