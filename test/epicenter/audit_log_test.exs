defmodule Epicenter.AuditLogTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.AuditLog
  alias Epicenter.Test
  alias Epicenter.Cases
  alias Epicenter.Accounts
  alias Epicenter.Cases.Person
  alias Epicenter.AuditLog.Revision

  describe "updating" do
    test "it creates revision, and submits the original changeset" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      attrs_to_change = Test.Fixtures.add_demographic_attrs(%{})
      changeset = Cases.change_person(person, attrs_to_change)

      {:ok, revision} = AuditLog.create_revision(
        changeset, user.id, Revision.edit_profile_demographics_event(), Revision.update_demographics_action())

      assert revision.author_id == user.id
      assert %{tid: "alice"} = revision.before_change
      assert ^attrs_to_change = revision.change
      assert revision.changed_id == person.id
      assert revision.changed_type == Cases.Person
      assert revision.reason_event == "edit-profile-demographics"
      assert revision.reason_action == "update-demographics"
      assert revision.seq == 2
    end
  end
end
