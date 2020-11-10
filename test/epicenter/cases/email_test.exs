defmodule Epicenter.Cases.EmailTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Email
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.Email,
        [
          {:address, :string},
          {:id, :binary_id},
          {:inserted_at, :naive_datetime},
          {:is_preferred, :boolean},
          {:person_id, :binary_id},
          {:seq, :integer},
          {:source, :string},
          {:tid, :string},
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      {default_attrs, _} = Test.Fixtures.email_attrs(user, person, "alice-email")
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

    test "validates personal health information on address", do: assert_invalid(new_changeset(address: "test@google.com"))

    test "marks changeset for delete only when delete flag is true" do
      new_changeset = new_changeset(%{})
      assert new_changeset.action == nil

      changeset = new_changeset |> Repo.insert!() |> Email.changeset(%{delete: true})
      assert changeset.action == :delete
    end
  end

  describe "query" do
    import Euclid.Extra.Enum, only: [tids: 1]

    test "display_order sorts preferred first, then by email address" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, person, "preferred", is_preferred: true, address: "m@example.com") |> Cases.create_email!()
      Test.Fixtures.email_attrs(user, person, "address-z", is_preferred: false, address: "z@example.com") |> Cases.create_email!()
      Test.Fixtures.email_attrs(user, person, "address-a", is_preferred: nil, address: "a@example.com") |> Cases.create_email!()

      Email.Query.display_order() |> Repo.all() |> tids() |> assert_eq(~w{preferred address-a address-z})
    end
  end

  describe "create_email!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(creator, "alice") |> Cases.create_person!()

      %{creator: creator, person: person}
    end

    test "it persists the correct values", %{person: person, creator: creator} do
      email =
        Test.Fixtures.email_attrs(creator, person, "preferred", is_preferred: true, address: "email@example.com", tid: "email1")
        |> Cases.create_email!()

      assert email.address == "email@example.com"
      assert email.is_preferred == true
      assert email.tid == "email1"
      assert email.person_id == person.id
    end

    test "has a revision count", %{person: person, creator: creator} do
      email =
        Test.Fixtures.email_attrs(creator, person, "preferred", is_preferred: true, address: "email@example.com", tid: "email1")
        |> Cases.create_email!()

      assert_revision_count(email, 1)
    end

    test "has an audit log", %{person: person, creator: creator} do
      email =
        Test.Fixtures.email_attrs(creator, person, "preferred", is_preferred: true, address: "email@example.com", tid: "email1")
        |> Cases.create_email!()

      assert_recent_audit_log(email, creator, %{
        "tid" => "email1",
        "address" => "email@example.com",
        "person_id" => person.id,
        "is_preferred" => true
      })
    end
  end
end
