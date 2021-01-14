defmodule Epicenter.Accounts.UserTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Accounts
  alias Epicenter.Accounts.User
  alias Epicenter.Cases
  alias Epicenter.Test
  alias Euclid.Extra

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        User,
        [
          {:admin, :boolean},
          {:confirmed_at, :utc_datetime},
          {:email, :string},
          {:hashed_password, :string},
          {:disabled, :boolean},
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:mfa_secret, :string},
          {:name, :string},
          {:seq, :bigserial},
          {:tid, :string},
          {:updated_at, :utc_datetime}
        ]
      )
    end
  end

  describe "associations" do
    test "has many assignments" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()

      Cases.assign_user_to_people(
        user_id: user.id,
        people_ids: [alice.id, billy.id],
        audit_meta: Test.Fixtures.audit_meta(user),
        current_user: @admin
      )

      user
      |> Accounts.preload_assignments()
      |> Map.get(:assignments)
      |> tids()
      |> assert_eq(~w{alice billy}, ignore_order: true)
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      {default_attrs, _} = Test.Fixtures.user_attrs(@admin, "alice")
      Accounts.change_user(%User{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))

    test "admin" do
      changes = new_changeset(%{admin: true}).changes
      assert changes.admin
    end

    test "name is required", do: assert_invalid(new_changeset(name: nil))

    test "email must be unique" do
      alice = Test.Fixtures.user_attrs(@admin, "alice") |> Accounts.register_user!()

      {:error, changeset} = Test.Fixtures.user_attrs(@admin, "billy", email: alice.email) |> Accounts.register_user()
      assert errors_on(changeset).email == ["has already been taken"]
    end
  end

  describe "json encoding" do
    test "it redacts secret values from serialization" do
      alice_audit_meta_tuple =
        {_, audit_meta} = Test.Fixtures.user_attrs(@admin, "alice", %{password: "alice's password", mfa_secret: "alice's authenticator"})

      alice = alice_audit_meta_tuple |> Accounts.register_user!() |> Accounts.update_user_mfa!({"alice's authenticator", audit_meta})
      json = Jason.encode!(alice)
      refute json =~ ~r/alice's password/
      refute json =~ alice.hashed_password
      refute json =~ ~r/alice's authenticator/
    end

    test "it omits developer utility values from serialization" do
      alice = Test.Fixtures.user_attrs(@admin, "alice") |> Accounts.register_user!()
      json = Jason.encode!(alice)
      refute json =~ ~r/"seq"/
    end
  end

  describe "filter_by_valid_password" do
    test "returns the user if the password matches or nil if it doesn't" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      assert User.filter_by_valid_password(user, "password123") == user
      assert User.filter_by_valid_password(user, "bad password") == nil
    end

    test "returns nil if no user is passed in" do
      assert User.filter_by_valid_password(nil, "bad password") == nil
    end
  end

  describe "query" do
    test "all/0 sorts by name, ignoring case" do
      Test.Fixtures.user_attrs(@admin, "middle", name: "Middle") |> Accounts.register_user!()
      Test.Fixtures.user_attrs(@admin, "first", name: "a-first") |> Accounts.register_user!()
      Test.Fixtures.user_attrs(@admin, "last", name: "z-last") |> Accounts.register_user!()

      User.Query.all() |> Repo.all() |> Extra.Enum.pluck(:name) |> assert_eq(["a-first", "fixture admin", "Middle", "z-last"])
    end
  end
end
