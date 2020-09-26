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
          {:is_preferred, :boolean},
          {:number, :integer},
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
      user = Test.Fixtures.user_attrs("user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      default_attrs = Test.Fixtures.phone_attrs(person, "phone")
      Phone.changeset(%Phone{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      changes = new_changeset(is_preferred: true).changes
      assert changes.is_preferred == true
      assert changes.number == 1_111_111_000
      assert changes.type == "home"
      assert changes.tid == "phone"
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "number is required", do: assert_invalid(new_changeset(number: nil))
    test "person_id is required", do: assert_invalid(new_changeset(person_id: nil))

    test "validates personal health information on number", do: assert_invalid(new_changeset(number: 2_111_111_000))
  end

  describe "query" do
    import Euclid.Extra.Enum, only: [tids: 1]

    test "display_order sorts preferred first, then by number" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.phone_attrs(person, "preferred", is_preferred: true, number: 1_111_111_222) |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(person, "phone-333", is_preferred: false, number: 1_111_111_333) |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(person, "phone-111", is_preferred: nil, number: 1_111_111_111) |> Cases.create_phone!()

      Phone.Query.display_order() |> Repo.all() |> tids() |> assert_eq(~w{preferred phone-111 phone-333})
    end
  end
end
