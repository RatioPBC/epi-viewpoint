defmodule Epicenter.Accounts.UserTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Accounts.User
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
