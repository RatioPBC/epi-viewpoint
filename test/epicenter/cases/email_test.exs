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
          {:address, :string},
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:is_preferred, :boolean},
          {:person_id, :id},
          {:seq, :integer},
          {:tid, :string},
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      user = Test.Fixtures.user_attrs("user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      default_attrs = Test.Fixtures.email_attrs(person, "alice-email")
      Email.changeset(%Email{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      changes = new_changeset(is_preferred: true).changes
      assert changes.address == "alice-email@example.com"
      assert changes.is_preferred == true
      assert changes.tid == "alice-email"
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "address is required", do: assert_invalid(new_changeset(address: nil))
    test "person_id is required", do: assert_invalid(new_changeset(person_id: nil))

    test "validates personal health information on address", do: assert_invalid(new_changeset(address: "test@google.com"))
  end

  describe "query" do
    import Euclid.Extra.Enum, only: [tids: 1]

    test "display_order sorts preferred first, then by email address" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.email_attrs(person, "preferred", is_preferred: true, address: "m@example.com") |> Cases.create_email!()
      Test.Fixtures.email_attrs(person, "address-z", is_preferred: false, address: "z@example.com") |> Cases.create_email!()
      Test.Fixtures.email_attrs(person, "address-a", is_preferred: nil, address: "a@example.com") |> Cases.create_email!()

      Email.Query.display_order() |> Repo.all() |> tids() |> assert_eq(~w{preferred address-a address-z})
    end
  end
end
