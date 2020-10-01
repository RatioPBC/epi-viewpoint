defmodule Epicenter.AuditLogTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Test

  describe "inserting" do
    test "it creates revision, and submits the original changeset" do
      assert [] = AuditLog.revisions(Cases.Person)

      user = Test.Fixtures.user_attrs("user") |> Accounts.register_user!()
      {attrs_to_change_1, _audit_meta} = Test.Fixtures.person_attrs(user, "alice")
      changeset_1 = Cases.change_person(%Person{}, attrs_to_change_1)

      {:ok, inserted_person_1} =
        AuditLog.insert(
          changeset_1,
          user.id,
          Revision.edit_profile_demographics_event(),
          Revision.update_demographics_action()
        )

      assert [revision_1] = AuditLog.revisions(Cases.Person)

      {attrs_to_change_2, _audit_meta} = Test.Fixtures.person_attrs(user, "billy")
      changeset_2 = Cases.change_person(%Person{}, attrs_to_change_2)

      inserted_person_2 =
        AuditLog.insert!(
          changeset_2,
          user.id,
          Revision.edit_profile_demographics_event(),
          Revision.update_demographics_action()
        )

      assert [_, revision_2] = AuditLog.revisions(Cases.Person)

      assert revision_1.changed_id == inserted_person_1.id
      assert revision_1.changed_type == "Cases.Person"
      assert revision_1.before_change["tid"] == nil
      assert revision_1.change["tid"] == "alice"
      assert revision_1.after_change["tid"] == "alice"
      assert revision_2.changed_id == inserted_person_2.id
      assert revision_2.changed_type == "Cases.Person"
      assert revision_2.before_change["tid"] == nil
      assert revision_2.change["tid"] == "billy"
      assert revision_2.after_change["tid"] == "billy"
    end
  end

  describe "updating" do
    test "it creates revision, and submits the original changeset" do
      assert [] = AuditLog.revisions(Cases.Person)

      user = Test.Fixtures.user_attrs("user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      person_id = person.id
      attrs_to_change = Test.Fixtures.add_demographic_attrs(%{})
      changeset = Cases.change_person(person, attrs_to_change)

      #      assert [%{changed_id: ^person_id}] = AuditLog.revisions(Cases.Person)

      {:ok, updated_person_1} =
        AuditLog.update(
          changeset,
          user.id,
          Revision.edit_profile_demographics_event(),
          Revision.update_demographics_action()
        )

      assert [%{changed_id: ^person_id}] = AuditLog.revisions(Cases.Person)

      updated_person_2 =
        AuditLog.update!(
          changeset,
          user.id,
          Revision.edit_profile_demographics_event(),
          Revision.update_demographics_action()
        )

      assert [revision_1, revision_2] = [%{changed_id: ^person_id}, %{changed_id: ^person_id}] = AuditLog.revisions(Cases.Person)

      assert revision_1.author_id == user.id
      assert revision_1.before_change["tid"] == "alice"
      assert revision_1.before_change["occupation"] == nil
      assert revision_1.change["occupation"] == "architect"
      assert revision_1.after_change["occupation"] == "architect"
      assert revision_1.changed_id == person.id
      assert revision_1.changed_type == "Cases.Person"
      assert revision_1.reason_event == "update-demographics"
      assert revision_1.reason_action == "edit-profile-demographics"

      assert revision_2.changed_id == person.id
      assert revision_2.changed_type == "Cases.Person"

      reloaded_person = Cases.get_person(person.id)
      reloaded_person |> Map.take(Map.keys(attrs_to_change)) |> assert_eq(attrs_to_change)

      assert updated_person_1.id == reloaded_person.id
      assert updated_person_2.id == reloaded_person.id
    end

    @tag :skip
    test "returns {:error, changeset} when changeset is invalid"

    # TODO ^ test error case
  end

  describe "module_name returns the name of a module, without leading application name" do
    test "with a struct" do
      assert AuditLog.module_name(%Revision{}) == "AuditLog.Revision"
    end

    test "with a module" do
      assert AuditLog.module_name(Revision) == "AuditLog.Revision"
    end
  end
end
