defmodule Epicenter.Cases.PhoneTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Phone
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.Phone,
        [
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:number, :integer},
          {:seq, :integer},
          {:tid, :string},
          {:type, :string},
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates \\ %{}) do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      default_attrs = Test.Fixtures.phone_attrs(user, "phone")
      Phone.changeset(%Phone{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      changes = new_changeset().changes
      assert changes.number == 5_105_551_000
      assert changes.type == "home"
      assert changes.originator.tid == "user"
      assert changes.tid == "phone"
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "number is required", do: assert_invalid(new_changeset(number: nil))

    test "validates personal health information on number", do: assert_invalid(new_changeset(number: 5_105_559_999))

    test "originator is required", do: assert_invalid(new_changeset(originator: nil))
    test "has originator virtual field", do: assert(new_changeset(%{}).changes.originator.tid == "user")
  end
end
