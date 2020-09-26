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
          {:confirmed_at, :naive_datetime},
          {:email, :string},
          {:hashed_password, :string},
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
      user = Test.Fixtures.user_attrs("user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Cases.assign_user_to_people(user_id: user.id, people_ids: [alice.id, billy.id], originator: user)

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
      Test.Fixtures.user_attrs("alice") |> Accounts.register_user!()

      {:error, changeset} = Test.Fixtures.user_attrs("alice", email: "new@example.com") |> Accounts.register_user()
      assert errors_on(changeset).username == ["has already been taken"]
    end

    test "email must be unique" do
      alice = Test.Fixtures.user_attrs("alice") |> Accounts.register_user!()

      {:error, changeset} = Test.Fixtures.user_attrs("billy", email: alice.email) |> Accounts.register_user()
      assert errors_on(changeset).email == ["has already been taken"]
    end
  end
end
