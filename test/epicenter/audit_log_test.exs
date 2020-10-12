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

      user = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "user") |> Accounts.register_user!()
      {attrs_to_change_1, _audit_meta} = Test.Fixtures.person_attrs(user, "alice")
      changeset_1 = Cases.change_person(%Person{}, attrs_to_change_1)

      {:ok, inserted_person_1} =
        AuditLog.insert(
          changeset_1,
          %AuditLog.Meta{
            author_id: user.id,
            reason_event: Revision.edit_profile_demographics_event(),
            reason_action: Revision.update_demographics_action()
          }
        )

      assert [revision_1] = AuditLog.revisions(Cases.Person)

      {attrs_to_change_2, _audit_meta} = Test.Fixtures.person_attrs(user, "billy")
      changeset_2 = Cases.change_person(%Person{}, attrs_to_change_2)

      inserted_person_2 =
        AuditLog.insert!(
          changeset_2,
          %AuditLog.Meta{
            author_id: user.id,
            reason_event: Revision.edit_profile_demographics_event(),
            reason_action: Revision.update_demographics_action()
          }
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

    test "omits passwords from the revision" do
      email = Epicenter.AccountsFixtures.unique_user_email()
      password = Epicenter.AccountsFixtures.valid_user_password()
      {user_attrs, _} = Test.Fixtures.user_attrs(%{id: ""}, "user", email: email, password: password)
      password_changeset = %Epicenter.Accounts.User{} |> Epicenter.Accounts.User.registration_changeset(user_attrs)

      {:ok, _inserted_user} =
        AuditLog.insert(
          password_changeset,
          %AuditLog.Meta{
            author_id: Ecto.UUID.generate(),
            reason_event: Revision.register_user_event(),
            reason_action: Revision.register_user_action()
          }
        )

      [revision] = AuditLog.revisions(Accounts.User)

      has_password_in_value = fn
        {_key, value} when is_binary(value) -> String.contains?(value, password)
        _ -> false
      end

      refute Enum.any?(revision.after_change, has_password_in_value)
      refute Enum.any?(revision.before_change, has_password_in_value)
      refute Enum.any?(revision.change, has_password_in_value)
    end

    test "omits mfa_secret from the revision" do
      mfa_secret = "123456"
      user = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "user") |> Accounts.register_user!()
      mfa_changeset = user |> Epicenter.Accounts.User.mfa_changeset(%{"mfa_secret" => mfa_secret})

      {:ok, _updated_user} =
        AuditLog.update(
          mfa_changeset,
          %AuditLog.Meta{
            author_id: Ecto.UUID.generate(),
            reason_event: "event",
            reason_action: "action"
          }
        )

      has_mfa_secret_in_value = fn
        {_key, value} when is_binary(value) -> String.contains?(value, mfa_secret)
        _ -> false
      end

      [_, revision] = AuditLog.revisions(Accounts.User)

      refute Enum.any?(revision.after_change, has_mfa_secret_in_value)
      refute Enum.any?(revision.before_change, has_mfa_secret_in_value)
      refute Enum.any?(revision.change, has_mfa_secret_in_value)
    end
  end

  describe "updating" do
    test "it creates revision, and submits the original changeset" do
      assert [] = AuditLog.revisions(Cases.Person)

      user = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      person_id = person.id
      attrs_to_change = Test.Fixtures.add_demographic_attrs(%{})
      changeset = Cases.change_person(person, attrs_to_change)

      assert [%{changed_id: ^person_id}] = AuditLog.revisions(Cases.Person)

      {:ok, updated_person_1} =
        AuditLog.update(
          changeset,
          %AuditLog.Meta{
            author_id: user.id,
            reason_event: Revision.edit_profile_demographics_event(),
            reason_action: Revision.update_demographics_action()
          }
        )

      assert [%{changed_id: ^person_id}, %{changed_id: ^person_id}] = AuditLog.revisions(Cases.Person)

      updated_person_2 =
        AuditLog.update!(
          changeset,
          %AuditLog.Meta{
            author_id: user.id,
            reason_event: Revision.edit_profile_demographics_event(),
            reason_action: Revision.update_demographics_action()
          }
        )

      assert [revision_0, revision_1, revision_2] =
               [%{changed_id: ^person_id}, %{changed_id: ^person_id}, %{changed_id: ^person_id}] = AuditLog.revisions(Cases.Person)

      assert revision_1.author_id == user.id
      assert revision_1.before_change["tid"] == "alice"
      assert revision_1.before_change["occupation"] == nil
      assert revision_1.change["occupation"] == "architect"
      assert revision_1.after_change["occupation"] == "architect"
      assert revision_1.changed_id == person.id
      assert revision_1.changed_type == "Cases.Person"
      assert revision_1.reason_event == "edit-profile-demographics"
      assert revision_1.reason_action == "update-demographics"

      assert revision_2.changed_id == person.id
      assert revision_2.changed_type == "Cases.Person"

      reloaded_person = Cases.get_person(person.id)
      reloaded_person |> Map.take(Map.keys(attrs_to_change)) |> assert_eq(attrs_to_change)

      assert updated_person_1.id == reloaded_person.id
      assert updated_person_2.id == reloaded_person.id
    end

    test "handling nested changesets (adding an email)" do
      user = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.preload_emails()

      person_params = %{
        "dob" => "1970-01-01",
        "emails" => %{
          "0" => %{
            "address" => "a@example.com",
            "delete" => "false",
            "person_id" => person.id
          }
        },
        "first_name" => person.first_name,
        "last_name" => person.last_name,
        "other_specified_language" => "",
        "preferred_language" => "English"
      }

      changeset = Cases.change_person(person, person_params)

      updated_person =
        AuditLog.update!(
          changeset,
          %AuditLog.Meta{author_id: user.id, reason_action: "action", reason_event: "event"}
        )

      assert [%{address: "a@example.com"}] = updated_person.emails

      assert_audit_logged(person)

      assert_recent_audit_log(person, user, %{
        "dob" => "1970-01-01",
        "emails" => [%{"address" => "a@example.com", "delete" => false, "person_id" => person.id}],
        "fingerprint" => "1970-01-01 alice testuser"
      })

      assert_recent_audit_log_snapshots(
        person,
        user,
        %{"emails" => []},
        %{
          "emails" => [
            %{
              "address" => "a@example.com",
              "delete" => false,
              "is_preferred" => nil,
              "person_id" => person.id,
              "tid" => nil
            }
          ]
        }
      )
    end

    test "returns {:error, changeset} when changeset is invalid" do
      user = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.preload_emails()

      person_params = %{
        "first_name" => ""
      }

      changeset = Cases.change_person(person, person_params)

      assert {:error, _} =
               AuditLog.update(
                 changeset,
                 %AuditLog.Meta{author_id: user.id, reason_action: "action", reason_event: "event"}
               )

      # only the "create" action should have a revision. not the invalid update.
      assert_revision_count(person, 1)
    end
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
