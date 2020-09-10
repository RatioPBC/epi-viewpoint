defmodule Epicenter.Cases.AddressTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Address
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.Address,
        [
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:full_address, :string},
          {:type, :string},
          {:person_id, :id},
          {:seq, :integer},
          {:tid, :string},
          {:updated_at, :naive_datetime},
          {:is_preferred, :boolean}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      default_attrs = Test.Fixtures.address_attrs(person, "alice-address")
      Address.changeset(%Address{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      changes = new_changeset(is_preferred: true).changes
      assert changes.full_address == "123 alice-address st, TestAddress"
      assert changes.tid == "alice-address"
      assert changes.type == "home"
      assert changes.is_preferred == true
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "full_address is required", do: assert_invalid(new_changeset(full_address: nil))
    test "person_id is required", do: assert_invalid(new_changeset(person_id: nil))

    test "validates personal health information on address", do: assert_invalid(new_changeset(full_address: "123 main st, sf ca"))
  end
end
