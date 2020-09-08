defmodule Epicenter.Accounts.UserTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Accounts
  alias Epicenter.Accounts.User
  alias Epicenter.Cases
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        User,
        [
          {:id, :binary_id},
          {:inserted_at, :naive_datetime},
          {:seq, :bigserial},
          {:tid, :string},
          {:updated_at, :naive_datetime},
          {:username, :string}
        ]
      )
    end
  end

  describe "associations" do
    test "has many assignments" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.update_assignment(user)
      Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!() |> Cases.update_assignment(user)

      user
      |> Accounts.preload_assignments()
      |> Map.get(:assignments)
      |> tids()
      |> assert_eq(~w{alice billy}, ignore_order: true)
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      default_attrs = Test.Fixtures.user_attrs("alice")
      Accounts.change_user(%User{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "username is required", do: assert_invalid(new_changeset(username: nil))

    test "username must be unique" do
      Test.Fixtures.user_attrs("alice") |> Accounts.create_user!()

      {:error, changeset} = Test.Fixtures.user_attrs("alice") |> Accounts.create_user()
      assert errors_on(changeset).username == ["has already been taken"]
    end
  end
end
