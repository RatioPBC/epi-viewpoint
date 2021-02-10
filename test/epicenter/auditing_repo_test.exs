defmodule Epicenter.AuditingRepoTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]
  import ExUnit.CaptureLog

  alias Epicenter.Accounts
  alias Epicenter.AuditingRepo
  alias Epicenter.AuditLog
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.ContactInvestigations
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.Test
  alias Epicenter.Test.AuditLogAssertions

  setup :persist_admin
  @admin Test.Fixtures.admin()

  # This indirectly uses the prod logger so we
  # can test the formatting of the logs in this test
  defmodule StubNotStub do
    @behaviour Epicenter.AuditLog.PhiLogger

    def info(message, logged_metadata, unlogged_metadata),
      do: Epicenter.AuditLog.PhiLogger.info(message, logged_metadata, unlogged_metadata)
  end

  setup do
    Mox.stub_with(Epicenter.Test.PhiLoggerMock, StubNotStub)
    :ok
  end

  describe "inserting" do
    test "it creates revision, and submits the original changeset" do
      assert [] = AuditingRepo.revisions(Cases.Person)

      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      {attrs_to_change_1, _audit_meta} = Test.Fixtures.person_attrs(user, "alice")
      changeset_1 = Cases.change_person(%Person{}, attrs_to_change_1)

      {:ok, inserted_person_1} =
        AuditingRepo.insert(
          changeset_1,
          %AuditLog.Meta{
            author_id: user.id,
            reason_event: Revision.edit_profile_demographics_event(),
            reason_action: Revision.update_demographics_action()
          }
        )

      assert [revision_1] = AuditingRepo.revisions(Cases.Person)

      {attrs_to_change_2, _audit_meta} = Test.Fixtures.person_attrs(user, "billy")
      changeset_2 = Cases.change_person(%Person{}, attrs_to_change_2)

      inserted_person_2 =
        AuditingRepo.insert!(
          changeset_2,
          %AuditLog.Meta{
            author_id: user.id,
            reason_event: Revision.edit_profile_demographics_event(),
            reason_action: Revision.update_demographics_action()
          }
        )

      assert [_, revision_2] = AuditingRepo.revisions(Cases.Person)

      assert revision_1.changed_id == inserted_person_1.id
      assert revision_1.changed_type == "Cases.Person"
      assert revision_1.before_change["tid"] == nil
      assert revision_1.change["tid"] == "alice"
      assert revision_1.after_change["tid"] == "alice"
      assert revision_1.application_version_sha == "test-version-sha"
      assert revision_2.changed_id == inserted_person_2.id
      assert revision_2.changed_type == "Cases.Person"
      assert revision_2.before_change["tid"] == nil
      assert revision_2.change["tid"] == "billy"
      assert revision_2.after_change["tid"] == "billy"
      assert revision_2.application_version_sha == "test-version-sha"
    end

    test "omits passwords from the revision" do
      email = Epicenter.AccountsFixtures.unique_user_email()
      password = Epicenter.AccountsFixtures.valid_user_password()
      {user_attrs, _} = Test.Fixtures.user_attrs(%{id: ""}, "user", email: email, password: password)
      password_changeset = %Epicenter.Accounts.User{} |> Epicenter.Accounts.User.registration_changeset(user_attrs)

      {:ok, _inserted_user} =
        AuditingRepo.insert(
          password_changeset,
          %AuditLog.Meta{
            author_id: Ecto.UUID.generate(),
            reason_event: Revision.register_user_event(),
            reason_action: Revision.register_user_action()
          }
        )

      [revision] = AuditingRepo.revisions(Accounts.User)

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
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      mfa_changeset = user |> Epicenter.Accounts.User.mfa_changeset(%{"mfa_secret" => mfa_secret})

      {:ok, _updated_user} =
        AuditingRepo.update(
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

      [_, revision] = AuditingRepo.revisions(Accounts.User)

      refute Enum.any?(revision.after_change, has_mfa_secret_in_value)
      refute Enum.any?(revision.before_change, has_mfa_secret_in_value)
      refute Enum.any?(revision.change, has_mfa_secret_in_value)
    end
  end

  describe "updating" do
    test "it creates revision, and submits the original changeset" do
      assert [] = AuditingRepo.revisions(Cases.Person)

      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.preload_demographics()
      person_id = person.id
      [%{id: demographic_id}] = person.demographics
      changeset = Cases.change_person(person, Test.Fixtures.add_demographic_attrs(%{tid: "someone"}, %{id: demographic_id, first_name: "alice1"}))

      assert [%{changed_id: ^person_id}] = AuditingRepo.revisions(Cases.Person)

      {:ok, updated_person_1} =
        AuditingRepo.update(
          changeset,
          %AuditLog.Meta{
            author_id: user.id,
            reason_event: Revision.edit_profile_demographics_event(),
            reason_action: Revision.update_demographics_action()
          }
        )

      assert [%{changed_id: ^person_id}, %{changed_id: ^person_id}] = AuditingRepo.revisions(Cases.Person)

      changeset =
        Cases.change_person(updated_person_1, Test.Fixtures.add_demographic_attrs(%{tid: "someone"}, %{id: demographic_id, first_name: "alice2"}))

      {:ok, _updated_person_2} =
        AuditingRepo.update(
          changeset,
          %AuditLog.Meta{
            author_id: user.id,
            reason_event: Revision.edit_profile_demographics_event(),
            reason_action: Revision.update_demographics_action()
          }
        )

      assert [_revision_0, revision_1, revision_2] =
               [%{changed_id: ^person_id}, %{changed_id: ^person_id}, %{changed_id: ^person_id}] = AuditingRepo.revisions(Cases.Person)

      assert revision_1.author_id == user.id
      assert revision_1.before_change["tid"] == "alice"

      demographic = fn
        %{"demographics" => [demographic | []]} -> demographic
        _ -> nil
      end

      assert demographic.(revision_1.change)["first_name"] == "alice1"

      assert revision_1.changed_id == person.id
      assert revision_1.changed_type == "Cases.Person"
      assert revision_1.reason_event == "edit-profile-demographics"
      assert revision_1.reason_action == "update-demographics"

      assert revision_2.changed_id == person.id
      assert revision_2.changed_type == "Cases.Person"
      assert demographic.(revision_2.change)["first_name"] == "alice2"
    end

    test "handling nested changesets (adding an email)" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.preload_emails() |> Cases.preload_demographics()

      person_params = %{
        "emails" => %{
          "0" => %{
            "address" => "a@example.com",
            "delete" => "false",
            "person_id" => person.id
          }
        }
      }

      changeset = Cases.change_person(person, person_params)

      updated_person =
        AuditingRepo.update!(
          changeset,
          %AuditLog.Meta{author_id: user.id, reason_action: "action", reason_event: "event"}
        )

      assert [%{address: "a@example.com"}] = updated_person.emails

      assert_audit_logged(person)

      assert_recent_audit_log(person, user, %{
        "emails" => [%{"address" => "a@example.com", "delete" => false, "person_id" => person.id}]
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

    test "handling nested changesets (updating an email)" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      person_params = %{
        dob: "1970-01-01",
        emails: %{
          "0" => %{
            "address" => "a@example.com",
            "delete" => "false"
          }
        },
        other_specified_language: "",
        preferred_language: "English"
      }

      person = Test.Fixtures.person_attrs(user, "alice", person_params) |> Cases.create_person!() |> Cases.preload_emails()

      update_email_params = %{
        "emails" => %{
          "0" => %{
            "address" => "a+test@example.com",
            "delete" => "false",
            "person_id" => person.id,
            "id" => person |> Map.get(:emails) |> Euclid.Extra.List.first() |> Map.get(:id)
          }
        }
      }

      changeset = Cases.change_person(person, update_email_params)

      updated_person =
        AuditingRepo.update!(
          changeset,
          %AuditLog.Meta{author_id: user.id, reason_action: "action", reason_event: "event"}
        )

      assert [%{address: "a+test@example.com", id: email_id}] = updated_person.emails

      assert_audit_logged(person)

      assert_recent_audit_log(person, user, %{
        "emails" => [%{"address" => "a+test@example.com"}]
      })

      assert_recent_audit_log_snapshots(
        person,
        user,
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
        },
        %{
          "emails" => [
            %{
              "address" => "a+test@example.com",
              "delete" => false,
              "is_preferred" => nil,
              "person_id" => person.id,
              "tid" => nil
            }
          ]
        }
      )

      assert %{"emails" => [%{"id" => ^email_id}]} = recent_audit_log(person).change
    end

    test "returns {:error, changeset} when changeset is invalid" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.preload_assigned_to()

      person_params = %{
        "assigned_to" => nil
      }

      changeset = Cases.change_person(person, person_params) |> Ecto.Changeset.validate_required(:assigned_to)

      assert {:error, _} =
               AuditingRepo.update(
                 changeset,
                 %AuditLog.Meta{author_id: user.id, reason_action: "action", reason_event: "event"}
               )

      # only the "create" action should have a revision. not the invalid update.
      assert_revision_count(person, 1)
    end
  end

  describe "audit log and change are in the same transaction" do
    test "it doesn't save the insert if the audit log entry fails" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      changeset = %Person{} |> Cases.change_person(elem(Test.Fixtures.person_attrs(user, "tid"), 0))
      people_count_before = Cases.count_people()
      audit_log_count_before = AuditingRepo.revisions(Cases.Person) |> length()

      assert catch_throw(
               AuditingRepo.insert(
                 changeset,
                 %AuditLog.Meta{
                   author_id: Ecto.UUID.generate(),
                   reason_event: Revision.register_user_event(),
                   reason_action: Revision.register_user_action()
                 },
                 [],
                 fn _ -> throw("intentional") end
               )
             ) == "intentional"

      assert people_count_before == Cases.count_people()
      assert audit_log_count_before == AuditingRepo.revisions(Cases.Person) |> length()
    end

    test "it doesn't save the update if the audit log entry fails" do
      [] = AuditingRepo.revisions(Cases.Person)

      person = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!() |> Cases.preload_demographics()

      person_id = person.id

      attrs_to_change =
        Test.Fixtures.add_demographic_attrs(%{tid: person.tid}, %{id: List.first(person.demographics).id, preferred_language: "preferred_language"})

      changeset = Cases.change_person(person, attrs_to_change)

      [%{changed_id: ^person_id}] = AuditingRepo.revisions(Cases.Person)
      audit_log_count_before = AuditingRepo.entries_for(person_id) |> length()

      assert catch_throw(
               AuditingRepo.update(
                 changeset,
                 %AuditLog.Meta{
                   author_id: @admin.id,
                   reason_event: Revision.edit_profile_demographics_event(),
                   reason_action: Revision.update_demographics_action()
                 },
                 [],
                 fn _ -> throw("intentional") end
               )
             ) == "intentional"

      refute List.first(Cases.preload_demographics(Cases.get_person(person_id, @admin)).demographics).preferred_language == "preferred_language"
      assert audit_log_count_before == AuditingRepo.entries_for(person_id) |> length()
    end
  end

  describe "module_name returns the name of a module, without leading application name" do
    test "with a struct" do
      assert AuditingRepo.module_name(%Revision{}) == "AuditLog.Revision"
    end

    test "with a module" do
      assert AuditingRepo.module_name(Revision) == "AuditLog.Revision"
    end
  end

  describe "view" do
    setup do
      original_metadata = Logger.metadata()
      {:ok, original_logger_config} = Application.fetch_env(:logger, :console)

      on_exit(fn ->
        Logger.metadata(original_metadata)
        Application.put_env(:logger, :console, original_logger_config)
      end)

      [
        user: %Accounts.User{id: "testuser"},
        subject: %Person{id: "testperson"}
      ]
    end

    test "formats the log message and uses info level", %{user: user, subject: subject} do
      Application.put_env(:logger, :console, format: "$level - $message")

      assert capture_log(fn ->
               AuditingRepo.view(subject, user)
             end) =~ "info - User(testuser) viewed Person(testperson)"
    end

    test "sets `audit_log: true` metadata", %{user: user, subject: subject} do
      Application.put_env(:logger, :console, format: "$metadata[audit_log]", metadata: [:audit_log])

      assert capture_log(fn ->
               AuditingRepo.view(subject, user)
             end) =~ "audit_log=true"
    end

    test "sets audit_user_id metadata", %{user: user, subject: subject} do
      Application.put_env(:logger, :console, format: "$metadata[audit_user_id]", metadata: [:audit_user_id])

      assert capture_log(fn ->
               AuditingRepo.view(subject, user)
             end) =~ "audit_user_id=testuser"
    end

    test "sets `audit_action: 'view'` metadata", %{user: user, subject: subject} do
      Application.put_env(:logger, :console, format: "$metadata[audit_action]", metadata: [:audit_action])

      assert capture_log(fn ->
               AuditingRepo.view(subject, user)
             end) =~ "audit_action=view"
    end

    test "sets audit_subject_id and audit_subject_type metadata", %{user: user, subject: subject} do
      Application.put_env(:logger, :console,
        format: "$metadata[audit_subject_type] $metadata[audit_subject_id]",
        metadata: [:audit_subject_type, :audit_subject_id]
      )

      assert capture_log(fn ->
               AuditingRepo.view(subject, user)
             end) =~ "audit_subject_type=Person audit_subject_id=testperson"
    end

    test "a list of people", %{user: user, subject: subject} do
      Application.put_env(:logger, :console, format: "$message")
      audit_log = capture_log(fn -> AuditingRepo.view([subject, %Person{id: "testperson2"}], user) end)

      assert audit_log =~ "User(testuser) viewed Person(testperson)"
      assert audit_log =~ "User(testuser) viewed Person(testperson2)"
    end

    test "it doesn't log a person if the person is nil", %{user: user} do
      assert capture_log(fn ->
               AuditingRepo.view(nil, user)
             end) == ""
    end

    @tag :skip
    test "it doesn't log a person when the id is missing", %{user: user} do
      assert capture_log(fn ->
               AuditingRepo.view(%Person{}, user)
             end) == ""
    end
  end

  describe "getting" do
    setup do
      original_metadata = Logger.metadata()
      {:ok, original_logger_config} = Application.fetch_env(:logger, :console)

      on_exit(fn ->
        Logger.metadata(original_metadata)
        Application.put_env(:logger, :console, original_logger_config)
      end)

      person = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, @admin, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "investigation", %{})
        |> Cases.create_case_investigation!()

      {:ok, contact_investigation} =
        Test.Fixtures.contact_investigation_attrs("contact-investigation-tid", %{exposing_case_id: case_investigation.id})
        |> Test.Fixtures.wrap_with_audit_meta()
        |> ContactInvestigations.create()

      [
        user: %Accounts.User{id: "testuser"},
        contact_investigation: contact_investigation
      ]
    end

    test "it records the record", %{user: user, contact_investigation: contact_investigation} do
      fetched_contact_investigation = AuditingRepo.get(ContactInvestigation, contact_investigation.id, user)
      assert fetched_contact_investigation.tid == "contact-investigation-tid"
    end

    test "formats the log message and uses info level", %{user: user, contact_investigation: contact_investigation} do
      Application.put_env(:logger, :console, format: "$level - $message")

      assert capture_log(fn ->
               AuditingRepo.get(ContactInvestigation, contact_investigation.id, user)
             end) =~ "info - User(testuser) viewed Person(#{contact_investigation.exposed_person_id})"
    end

    test "sets `audit_log: true` metadata", %{user: user, contact_investigation: contact_investigation} do
      Application.put_env(:logger, :console, format: "$metadata[audit_log]", metadata: [:audit_log])

      assert capture_log(fn ->
               AuditingRepo.get(ContactInvestigation, contact_investigation.id, user)
             end) =~ "audit_log=true"
    end

    test "sets audit_user_id metadata", %{user: user, contact_investigation: contact_investigation} do
      Application.put_env(:logger, :console, format: "$metadata[audit_user_id]", metadata: [:audit_user_id])

      assert capture_log(fn ->
               AuditingRepo.get(ContactInvestigation, contact_investigation.id, user)
             end) =~ "audit_user_id=testuser"
    end

    test "sets `audit_action: 'view'` metadata", %{user: user, contact_investigation: contact_investigation} do
      Application.put_env(:logger, :console, format: "$metadata[audit_action]", metadata: [:audit_action])

      assert capture_log(fn ->
               AuditingRepo.get(ContactInvestigation, contact_investigation.id, user)
             end) =~ "audit_action=view"
    end

    test "sets audit_subject_id and audit_subject_type metadata", %{user: user, contact_investigation: contact_investigation} do
      Application.put_env(:logger, :console,
        format: "$metadata[audit_subject_type] $metadata[audit_subject_id]",
        metadata: [:audit_subject_type, :audit_subject_id]
      )

      assert capture_log(fn ->
               AuditingRepo.get(ContactInvestigation, contact_investigation.id, user)
             end) =~ "audit_subject_type=Person audit_subject_id=#{contact_investigation.exposed_person_id}"
    end

    test "it doesn't log a person if the person is not found", %{user: user} do
      assert capture_log(fn ->
               AuditingRepo.get(ContactInvestigation, Ecto.UUID.generate(), user)
             end) == ""
    end
  end

  describe "all'ing" do
    setup do
      alice = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      billy = Test.Fixtures.person_attrs(@admin, "billy") |> Cases.create_person!()

      [alice: alice, billy: billy]
    end

    test "returns all the records for a given query" do
      assert Person.Query.filter_with_case_investigation(:all) |> AuditingRepo.all(@admin) |> tids() == ~w{alice billy}
    end

    test "records all the phi viewed for fetched records", %{alice: alice, billy: billy} do
      capture_log(fn -> Person.Query.filter_with_case_investigation(:all) |> AuditingRepo.all(@admin) end)
      |> AuditLogAssertions.assert_viewed_person(@admin, alice)
      |> AuditLogAssertions.assert_viewed_person(@admin, billy)
    end
  end
end
