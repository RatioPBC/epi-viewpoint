defmodule EpiViewpoint.Cases.PhoneTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Phone
  alias EpiViewpoint.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.Phone,
        [
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:is_preferred, :boolean},
          {:number, :string},
          {:person_id, :binary_id},
          {:seq, :integer},
          {:source, :string},
          {:tid, :string},
          {:type, :string},
          {:updated_at, :utc_datetime}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      {default_attrs, _} = Test.Fixtures.phone_attrs(user, person, "phone")
      Phone.changeset(%Phone{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes" do
      changes = new_changeset(is_preferred: true, source: "form").changes
      assert changes.is_preferred == true
      assert changes.number == "1111111000"
      assert changes.source == "form"
      assert changes.type == "home"
      assert changes.tid == "phone"
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "number is required", do: assert_invalid(new_changeset(number: nil))

    test "validates personal health information on number", do: assert_invalid(new_changeset(number: "211-111-1000"))

    test "marks changeset for delete only when delete flag is true" do
      new_changeset = new_changeset(%{})
      assert new_changeset.action == nil

      changeset = new_changeset |> Repo.insert!() |> Phone.changeset(%{delete: true})
      assert changeset.action == :delete
    end
  end

  describe "query" do
    import Euclid.Extra.Enum, only: [tids: 1]

    test "display_order sorts preferred first, then by number" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.phone_attrs(user, person, "preferred", is_preferred: true, number: "111-111-1222") |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(user, person, "phone-333", is_preferred: false, number: "111-111-1333") |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(user, person, "phone-111", is_preferred: nil, number: "111-111-1000") |> Cases.create_phone!()

      Phone.Query.display_order() |> Repo.all() |> tids() |> assert_eq(~w{preferred phone-111 phone-333})
    end
  end
end
