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
          {:address_fingerprint, :string},
          {:street, :string},
          {:city, :string},
          {:state, :string},
          {:postal_code, :string},
          {:id, :binary_id},
          {:inserted_at, :naive_datetime},
          {:is_preferred, :boolean},
          {:person_id, :binary_id},
          {:seq, :integer},
          {:source, :string},
          {:tid, :string},
          {:type, :string},
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end

  setup :persist_admin
  @admin Test.Fixtures.admin()
  describe "changeset" do
    defp new_changeset(attr_updates) do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      {default_attrs, _} = Test.Fixtures.address_attrs(user, person, "alice-address", 1234)
      Address.changeset(%Address{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      changes = new_changeset(is_preferred: true, source: "form").changes
      assert changes.street == "1234 Test St"
      assert changes.city == "City"
      assert changes.state == "OH"
      assert changes.postal_code == "00000"
      assert changes.tid == "alice-address"
      assert changes.type == "home"
      assert changes.is_preferred == true
      assert changes.source == "form"
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "street is optional", do: assert_valid(new_changeset(street: nil))
    test "city is optional", do: assert_valid(new_changeset(city: nil))
    test "state is optional", do: assert_valid(new_changeset(state: nil))
    test "postal_code is optional", do: assert_valid(new_changeset(postal_code: nil))

    test "validates personal health information on address", do: assert_invalid(new_changeset(street: "123 main st"))
  end

  describe "query" do
    import Euclid.Extra.Enum, only: [tids: 1]

    test "display_order sorts preferred first, then by full address" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.address_attrs(user, person, "preferred", 2000, is_preferred: true) |> Cases.create_address!()
      Test.Fixtures.address_attrs(user, person, "address-z", 3000, is_preferred: false) |> Cases.create_address!()
      Test.Fixtures.address_attrs(user, person, "address-a", 1000, is_preferred: nil) |> Cases.create_address!()

      Address.Query.display_order() |> Repo.all() |> tids() |> assert_eq(~w{preferred address-a address-z})
    end
  end
end
