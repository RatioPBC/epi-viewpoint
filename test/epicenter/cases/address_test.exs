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
          {:full_address, :string},
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:is_preferred, :boolean},
          {:person_id, :id},
          {:seq, :integer},
          {:tid, :string},
          {:type, :string},
          {:updated_at, :naive_datetime}
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

  describe "query" do
    import Euclid.Extra.Enum, only: [tids: 1]

    test "display_order sorts preferred first, then by full address" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.address_attrs(person, "preferred", is_preferred: true, full_address: "m TestAddress") |> Cases.create_address!()
      Test.Fixtures.address_attrs(person, "address-z", is_preferred: false, full_address: "z TestAddress") |> Cases.create_address!()
      Test.Fixtures.address_attrs(person, "address-a", is_preferred: nil, full_address: "a TestAddress") |> Cases.create_address!()

      Address.Query.display_order() |> Repo.all() |> tids() |> assert_eq(~w{preferred address-a address-z})
    end
  end
end