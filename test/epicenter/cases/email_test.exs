defmodule Epicenter.Cases.EmailTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Email
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.Email,
        [
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:address, :string},
          {:person_id, :id},
          {:seq, :integer},
          {:tid, :string},
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates \\ %{}) do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      default_attrs = Test.Fixtures.email_attrs(person, "alice-email")
      Email.changeset(%Email{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      changes = new_changeset().changes
      assert changes.address == "alice-email@example.com"
      assert changes.tid == "alice-email"
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "address is required", do: assert_invalid(new_changeset(address: nil))

    test "validates personal health information on address", do: assert_invalid(new_changeset(address: "test@google.com"))
  end
end
