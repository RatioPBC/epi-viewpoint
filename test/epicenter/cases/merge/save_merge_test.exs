defmodule Epicenter.Cases.SaveMergeTest do
  use Epicenter.DataCase, async: true

  import Epicenter.Test.RevisionAssertions
  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias Epicenter.Cases.Merge
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  setup do
    user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
    [user: user]
  end

  describe "identifying information" do
    test "emails, phones, and addresses from the duplicate person are copied to the canonical person", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, alice, "alice-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, alice, "alice-phone", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, alice, "alice-address", 1000, type: "home") |> Cases.create_address!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, billy, "billy-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, billy, "billy-phone", number: "111-111-1002") |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, billy, "billy-address", 1001, type: "home") |> Cases.create_address!()

      Merge.merge([billy], into: alice, with_attrs: %{}, current_user: user)
      alice = alice |> Cases.preload_addresses() |> Cases.preload_emails() |> Cases.preload_phones()
      assert alice.phones |> contains("alice-phone")
      assert alice.phones |> contains("billy-phone")
      assert alice.emails |> contains("alice-email")
      assert alice.emails |> contains("billy-email")
      assert alice.addresses |> contains("alice-address")
      assert alice.addresses |> contains("billy-address")
    end

    test "when duplicate person and canonical person have the same phone number", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, alice, "alice-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, alice, "alice-phone", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, alice, "alice-address", 1000, type: "home") |> Cases.create_address!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, billy, "billy-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, billy, "billy-phone", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, billy, "billy-address", 1000, type: "home") |> Cases.create_address!()

      Merge.merge([billy], into: alice, with_attrs: %{}, current_user: user)
      alice = alice |> Cases.preload_addresses() |> Cases.preload_emails() |> Cases.preload_phones()
      assert alice.phones |> tids() == ["alice-phone"]
      assert alice.emails |> tids() == ["alice-email", "billy-email"]
      assert alice.addresses |> tids() == ["alice-address"]
    end

    @tag :skip
    test "if adding one of the phone numbers fails?" do
    end

    defp contains(list, tid) do
      Enum.find(list, &(&1.tid == tid)) != nil
    end
  end

  describe "audit logging the merge" do
    # It would be more ideal if the objects the audit logs get tied to were the person
    # instead of the address, email, and phone objects themselves. This is a potential
    # improvement that we might want if we want to build UI for viewing the merge
    # history.
    test "it audit logs the creation of addresses/emails/phones", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.address_attrs(user, alice, "alice-address", 1000, type: "home") |> Cases.create_address!()
      Test.Fixtures.email_attrs(user, alice, "alice-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, alice, "alice-phone", number: "111-111-1000") |> Cases.create_phone!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Test.Fixtures.address_attrs(user, billy, "billy-address", 1001, type: "home") |> Cases.create_address!()
      Test.Fixtures.email_attrs(user, billy, "billy-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, billy, "billy-phone", number: "111-111-1002") |> Cases.create_phone!()

      Merge.merge([billy], into: alice, with_attrs: %{}, current_user: user)
      alice = alice |> Cases.preload_addresses() |> Cases.preload_emails() |> Cases.preload_phones()

      %{addresses: [_, new_address], emails: [_, new_email], phones: [_, new_phone]} = alice

      assert_semi_recent_audit_log(new_address, user, Revision.create_address_action(), Revision.save_merge_event(), %{
        "person_id" => alice.id
      })

      assert_semi_recent_audit_log(new_email, user, Revision.create_email_action(), Revision.save_merge_event(), %{
        "person_id" => alice.id
      })

      assert_semi_recent_audit_log(new_phone, user, Revision.create_phone_action(), Revision.save_merge_event(), %{
        "person_id" => alice.id
      })
    end
  end
end
