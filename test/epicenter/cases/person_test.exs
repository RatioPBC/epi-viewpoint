defmodule Epicenter.Cases.PersonTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Phone
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        Person,
        [
          {:assigned_to_id, :binary_id},
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:seq, :integer},
          {:tid, :string},
          {:updated_at, :utc_datetime}
        ]
      )
    end
  end

  describe "associations" do
    test "can have zero lab_results" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      alice |> Cases.preload_lab_results() |> Map.get(:lab_results) |> assert_eq([])
    end

    test "has many lab_results" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, user, "result1", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "result2", "06-02-2020") |> Cases.create_lab_result!()

      alice
      |> Cases.preload_lab_results()
      |> Map.get(:lab_results)
      |> tids()
      |> assert_eq(~w{result1 result2}, ignore_order: true)
    end

    test "has many case_investigations" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result1", ~D[2020-10-27]) |> Cases.create_lab_result!()
      Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation1") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation2") |> Cases.create_case_investigation!()

      alice
      |> Cases.preload_case_investigations()
      |> Map.get(:case_investigations)
      |> tids()
      |> assert_eq(~w{investigation1 investigation2}, ignore_order: true)
    end

    test "has many phone numbers" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.phone_attrs(user, alice, "phone-1", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(user, alice, "phone-2", number: "111-111-1001") |> Cases.create_phone!()

      assert alice |> Cases.preload_phones() |> Map.get(:phones) |> tids() == ~w{phone-1 phone-2}
    end

    test "has many email addresses" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, alice, "email-1") |> Cases.create_email!()
      Test.Fixtures.email_attrs(user, alice, "email-2") |> Cases.create_email!()

      assert alice |> Cases.preload_emails() |> Map.get(:emails) |> tids() == ~w{email-1 email-2}
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates, demographic_attrs \\ %{}) do
      default_attrs = Test.Fixtures.raw_person_attrs("alice", attr_updates) |> Test.Fixtures.add_demographic_attrs(demographic_attrs)
      Person.changeset(%Person{}, default_attrs)
    end

    test "assignment_changeset can assign or unassign a user to a person" do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      assigned_to = Test.Fixtures.user_attrs(@admin, "assigned-to") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(creator, "alice") |> Cases.create_person!()

      changeset = Person.assignment_changeset(alice, assigned_to)
      assert changeset.changes.assigned_to_id == assigned_to.id

      changeset = Person.assignment_changeset(changeset, nil)
      assert changeset.changes.assigned_to_id == nil
    end

    test "identifying attributes" do
      changes = new_changeset(%{}).changes
      assert changes.tid == "alice"
    end

    test "demographic attributes" do
      changes =
        (new_changeset(%{}, %{
           ethnicity: %{
             major: "hispanic_latinx_or_spanish_origin",
             detailed: ["cuban", "puerto_rican"]
           },
           external_id: "10000"
         }).changes.demographics
         |> List.first()).changes

      assert changes.dob == ~D[2000-01-01]
      assert changes.first_name == "Alice"
      assert changes.employment == "part_time"
      assert changes.external_id == "10000"
      assert changes.gender_identity == ["female"]
      assert changes.last_name == "Testuser"
      assert changes.marital_status == "single"
      assert changes.notes == "lorem ipsum"
      assert changes.occupation == "architect"
      assert changes.preferred_language == "English"
      assert changes.race == %{detailed: %{asian: ["filipino"]}, major: ["asian"]}
      assert changes.sex_at_birth == "female"

      ethnicity_changes = changes.ethnicity.changes
      assert ethnicity_changes.major == "hispanic_latinx_or_spanish_origin"
      assert ethnicity_changes.detailed == ["cuban", "puerto_rican"]
    end

    test "form demographics can be additively changed with a string (vs and atom)" do
      person = %Person{
        demographics: [
          %{
            source: "form",
            first_name: "Ally"
          }
        ]
      }

      changeset = Person.changeset(person, %{"form_demographic" => %{first_name: "Bill"}})

      assert {:ok, %{demographics: [%{source: "form", first_name: "Bill"}]}} = apply_action(changeset, :test)
    end

    # The caller must choose whether they are replacing the demographics, or additively changing them
    test "setting demographics and form_demographic at the same time is not supported" do
      person = %Person{
        demographics: [
          %Demographic{
            source: "form",
            first_name: "Ally"
          }
        ]
      }

      assert catch_throw(
               Person.changeset(person, %{
                 "demographics" => [
                   %{
                     source: "form",
                     first_name: "Ally2"
                   }
                 ],
                 "form_demographic" => %{first_name: "Bill"}
               })
             )
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))

    test "associations - emails" do
      email_changeset = new_changeset(%{emails: [%{address: "othertest@example.com"}]}).changes.emails |> Euclid.Extra.List.first()
      assert email_changeset.changes.address == "othertest@example.com"
    end

    test "associations - phones" do
      phone_changeset = new_changeset(%{phones: [%{number: "1111111003"}]}).changes.phones |> Euclid.Extra.List.first()
      assert phone_changeset.changes.number == "1111111003"
    end

    test "additively inserting a phone number without deleting any" do
      person = %Person{
        phones: [
          %Phone{
            number: "1111111000"
          }
        ]
      }

      changeset = Person.changeset(person, %{"additive_phone" => %{number: "1111111002", source: "blah"}})

      assert {:ok, %{phones: [%{number: "1111111000"}, %{source: "blah", number: "1111111002"}]}} = apply_action(changeset, :test)
    end

    test "additively inserting a phone number when the phone number already exists" do
      person = %Person{
        phones: [
          %Phone{
            number: "1111111000"
          }
        ]
      }

      changeset = Person.changeset(person, %{"additive_phone" => %{number: "1111111000", source: "blah"}})

      assert {:ok, %{phones: [%{number: "1111111000"}]}} = apply_action(changeset, :test)
    end

    test "additively inserting a phone number when the key is an atom" do
      person = %Person{
        phones: [
          %Phone{
            number: "1111111000"
          }
        ]
      }

      changeset = Person.changeset(person, %{:additive_phone => %{number: "1111111002", source: "blah"}})

      assert {:ok, %{phones: [%{number: "1111111000"}, %{source: "blah", number: "1111111002"}]}} = apply_action(changeset, :test)
    end

    # The caller must choose whether they are replacing the phones, or additively changing them
    test "setting phones and additive_phone at the same time is not supported" do
      person = %Person{
        phones: [
          %Phone{
            number: "1111111000"
          }
        ]
      }

      assert catch_throw(Person.changeset(person, %{:phones => [], :additive_phone => %{number: "1111111002", source: "blah"}}))
    end

    test "associations - address" do
      address_changeset =
        new_changeset(%{addresses: [%{street: "1023 Test St", city: "City7", state: "ZB", postal_code: "00002"}]}).changes.addresses
        |> Euclid.Extra.List.first()

      assert %{street: "1023 Test St", city: "City7", state: "ZB", postal_code: "00002"} = address_changeset.changes
    end
  end

  describe "latest_case_investigation" do
    test "returns nil if no lab results" do
      Test.Fixtures.user_attrs(@admin, "user")
      |> Accounts.register_user!()
      |> Test.Fixtures.person_attrs("alice")
      |> Cases.create_person!()
      |> Cases.preload_case_investigations()
      |> Person.latest_case_investigation()
      |> assert_eq(nil)
    end

    test "returns the case investigation with the most recent created at date" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      new_lab_result = Test.Fixtures.lab_result_attrs(alice, user, "new_lab_result", "06-02-2020") |> Cases.create_lab_result!()
      newer_lab_result = Test.Fixtures.lab_result_attrs(alice, user, "newer_lab_result", "06-02-2020") |> Cases.create_lab_result!()
      newest_lab_result = Test.Fixtures.lab_result_attrs(alice, user, "newest_lab_result", "06-02-2020") |> Cases.create_lab_result!()

      Test.Fixtures.case_investigation_attrs(alice, new_lab_result, user, "new") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(alice, newer_lab_result, user, "newer") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(alice, newest_lab_result, user, "newest") |> Cases.create_case_investigation!()

      alice = alice |> Cases.preload_case_investigations()

      assert Person.latest_case_investigation(alice).tid == "newest"
    end
  end

  describe "latest_lab_result" do
    test "returns nil if no lab results" do
      Test.Fixtures.user_attrs(@admin, "user")
      |> Accounts.register_user!()
      |> Test.Fixtures.person_attrs("alice")
      |> Cases.create_person!()
      |> Cases.preload_lab_results()
      |> Person.latest_lab_result()
      |> assert_eq(nil)
    end

    test "returns the lab result with the most recent sample date" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, user, "newer", "06-02-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "older", "06-01-2020") |> Cases.create_lab_result!()

      alice = alice |> Cases.preload_lab_results()
      assert Person.latest_lab_result(alice).tid == "newer"
    end

    test "when there is a null sampled_on, returns that record first" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, user, "newer", "06-02-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "older", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "unknown", nil) |> Cases.create_lab_result!()

      alice = alice |> Cases.preload_lab_results()
      assert Person.latest_lab_result(alice).tid == "unknown"
    end

    test "when there are two records with null sampled_on, returns the lab results with the largest seq" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, user, "unknown", nil) |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "newer unknown", nil) |> Cases.create_lab_result!()

      alice = alice |> Cases.preload_lab_results()
      assert Person.latest_lab_result(alice).tid == "newer unknown"
    end
  end

  describe "coalesce_demographics" do
    test "prioritizes manual data > old import data > new import data" do
      older_import_attrs = %{dob: ~D[2000-01-01], first_name: "Older-Import", source: "import", inserted_at: ~N[2020-01-01 00:00:00]}
      manual_attrs = %{first_name: "Manual", source: "form", inserted_at: ~N[2020-01-01 00:01:00]}

      newer_import_attrs = %{
        dob: ~D[2000-02-01],
        first_name: "Newer-Import",
        source: "import",
        last_name: "Testuser",
        inserted_at: ~N[2020-01-01 00:02:00]
      }

      person = %{demographics: [older_import_attrs, manual_attrs, newer_import_attrs]}

      coalesced_demographics = person |> Person.coalesce_demographics()

      assert coalesced_demographics.dob == older_import_attrs.dob
      assert coalesced_demographics.first_name == manual_attrs.first_name
      assert coalesced_demographics.last_name == newer_import_attrs.last_name
    end
  end

  # # # Query

  describe "all" do
    test "sorts by creation order" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      Test.Fixtures.person_attrs(user, "first", dob: ~D{2000-06-01}, first_name: "Alice", last_name: "Testuser") |> Cases.create_person!()
      Test.Fixtures.person_attrs(user, "middle", dob: ~D{2000-06-01}, first_name: "Billy", last_name: "Testuser") |> Cases.create_person!()
      Test.Fixtures.person_attrs(user, "last", dob: ~D{2000-07-01}, first_name: "Alice", last_name: "Testuser") |> Cases.create_person!()

      Person.Query.all() |> Epicenter.Repo.all() |> tids() |> assert_eq(~w{first middle last})
    end
  end

  describe "with_pending_interview" do
    test "sorts by assignee name, then tie-breaks with most recent positive lab result near the top" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      first_assignee = Test.Fixtures.user_attrs(@admin, "assignee") |> Accounts.register_user!()

      # Assigned last
      assigned_last = Test.Fixtures.person_attrs(user, "assigned_last") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(assigned_last, user, "assigned_last_1", ~D[2020-06-04], result: "negative") |> Cases.create_lab_result!()

      assigned_last_l_r =
        Test.Fixtures.lab_result_attrs(assigned_last, user, "assigned_last_2", ~D[2020-06-06], result: "pOsItIvE") |> Cases.create_lab_result!()

      Cases.assign_user_to_people(user: user, people_ids: [assigned_last.id], audit_meta: Test.Fixtures.admin_audit_meta())

      Test.Fixtures.case_investigation_attrs(assigned_last, assigned_last_l_r, user, "assigned_last_case_investigation")
      |> Cases.create_case_investigation!()

      # Assigned middle
      assigned_middle = Test.Fixtures.person_attrs(user, "assigned_middle") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(assigned_middle, user, "assigned_middle_1", ~D[2020-06-04], result: "negative") |> Cases.create_lab_result!()

      assigned_middle_l_r =
        Test.Fixtures.lab_result_attrs(assigned_middle, user, "assigned_middle_2", ~D[2020-06-05], result: "pOsItIvE") |> Cases.create_lab_result!()

      Cases.assign_user_to_people(user: first_assignee, people_ids: [assigned_middle.id], audit_meta: Test.Fixtures.admin_audit_meta())

      Test.Fixtures.case_investigation_attrs(assigned_middle, assigned_middle_l_r, user, "assigned_middle_case_investigation")
      |> Cases.create_case_investigation!()

      # Assigned first
      assigned_first = Test.Fixtures.person_attrs(user, "assigned_first") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(assigned_first, user, "assigned_first_1", ~D[2020-06-08], result: "DeTectEd") |> Cases.create_lab_result!()

      assigned_first_l_r =
        Test.Fixtures.lab_result_attrs(assigned_first, user, "assigned_first_2", ~D[2020-05-08], result: "DeTectEd") |> Cases.create_lab_result!()

      Cases.assign_user_to_people(user: first_assignee, people_ids: [assigned_first.id], audit_meta: Test.Fixtures.admin_audit_meta())

      Test.Fixtures.case_investigation_attrs(assigned_first, assigned_first_l_r, user, "assigned_first_case_investigation")
      |> Cases.create_case_investigation!()

      # Unassigned last
      unassigned_last = Test.Fixtures.person_attrs(user, "unassigned_last") |> Cases.create_person!()

      unassigned_last_l_r =
        Test.Fixtures.lab_result_attrs(unassigned_last, user, "unassigned_last_1", ~D[2020-05-03], result: "positive") |> Cases.create_lab_result!()

      Test.Fixtures.lab_result_attrs(unassigned_last, user, "unassigned_last_2", ~D[2020-06-04], result: "negative") |> Cases.create_lab_result!()

      Test.Fixtures.case_investigation_attrs(unassigned_last, unassigned_last_l_r, user, "unassigned_last_case_investigation")
      |> Cases.create_case_investigation!()

      # Unassigned first
      unassigned_first = Test.Fixtures.person_attrs(user, "unassigned_first") |> Cases.create_person!()

      unnassigned_first_l_r =
        Test.Fixtures.lab_result_attrs(unassigned_first, user, "unassigned_first_1", ~D[2020-06-03], result: "positive") |> Cases.create_lab_result!()

      Test.Fixtures.case_investigation_attrs(unassigned_first, unnassigned_first_l_r, user, "unassigned_first_case_investigation")
      |> Cases.create_case_investigation!()

      # Subject action
      Person.Query.with_pending_interview()
      |> Epicenter.Repo.all()
      |> Cases.preload_lab_results()
      |> tids()
      |> assert_eq(~w{unassigned_first unassigned_last assigned_first assigned_middle assigned_last})
    end
  end

  describe "with_ongoing_interview" do
    test "sorts by assignee name, then tie-breaks with most recent positive lab result near the top" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      first_assignee = Test.Fixtures.user_attrs(@admin, "assignee") |> Accounts.register_user!()

      # Assigned last
      assigned_last = Test.Fixtures.person_attrs(user, "assigned_last") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(assigned_last, user, "assigned_last_1", ~D[2020-06-04], result: "negative") |> Cases.create_lab_result!()

      assigned_last_l_r =
        Test.Fixtures.lab_result_attrs(assigned_last, user, "assigned_last_2", ~D[2020-06-06], result: "pOsItIvE") |> Cases.create_lab_result!()

      Cases.assign_user_to_people(user: user, people_ids: [assigned_last.id], audit_meta: Test.Fixtures.admin_audit_meta())

      Test.Fixtures.case_investigation_attrs(assigned_last, assigned_last_l_r, user, "assigned_last_case_investigation", %{
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      })
      |> Cases.create_case_investigation!()

      # Assigned middle
      assigned_middle = Test.Fixtures.person_attrs(user, "assigned_middle") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(assigned_middle, user, "assigned_middle_1", ~D[2020-06-04], result: "negative") |> Cases.create_lab_result!()

      assigned_middle_l_r =
        Test.Fixtures.lab_result_attrs(assigned_middle, user, "assigned_middle_2", ~D[2020-06-05], result: "pOsItIvE") |> Cases.create_lab_result!()

      Cases.assign_user_to_people(user: first_assignee, people_ids: [assigned_middle.id], audit_meta: Test.Fixtures.admin_audit_meta())

      Test.Fixtures.case_investigation_attrs(assigned_middle, assigned_middle_l_r, user, "assigned_middle_case_investigation", %{
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      })
      |> Cases.create_case_investigation!()

      # Assigned first
      assigned_first = Test.Fixtures.person_attrs(user, "assigned_first") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(assigned_first, user, "assigned_first_1", ~D[2020-06-08], result: "DeTectEd") |> Cases.create_lab_result!()

      assigned_first_l_r =
        Test.Fixtures.lab_result_attrs(assigned_first, user, "assigned_first_2", ~D[2020-05-08], result: "DeTectEd") |> Cases.create_lab_result!()

      Cases.assign_user_to_people(user: first_assignee, people_ids: [assigned_first.id], audit_meta: Test.Fixtures.admin_audit_meta())

      Test.Fixtures.case_investigation_attrs(assigned_first, assigned_first_l_r, user, "assigned_first_case_investigation", %{
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      })
      |> Cases.create_case_investigation!()

      # Unassigned last
      unassigned_last = Test.Fixtures.person_attrs(user, "unassigned_last") |> Cases.create_person!()

      unassigned_last_l_r =
        Test.Fixtures.lab_result_attrs(unassigned_last, user, "unassigned_last_1", ~D[2020-05-03], result: "positive") |> Cases.create_lab_result!()

      Test.Fixtures.lab_result_attrs(unassigned_last, user, "unassigned_last_2", ~D[2020-06-04], result: "negative") |> Cases.create_lab_result!()

      Test.Fixtures.case_investigation_attrs(unassigned_last, unassigned_last_l_r, user, "unassigned_last_case_investigation", %{
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      })
      |> Cases.create_case_investigation!()

      # Unassigned first
      unassigned_first = Test.Fixtures.person_attrs(user, "unassigned_first") |> Cases.create_person!()

      unnassigned_first_l_r =
        Test.Fixtures.lab_result_attrs(unassigned_first, user, "unassigned_first_1", ~D[2020-06-03], result: "positive") |> Cases.create_lab_result!()

      Test.Fixtures.case_investigation_attrs(unassigned_first, unnassigned_first_l_r, user, "unassigned_first_case_investigation", %{
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      })
      |> Cases.create_case_investigation!()

      # Subject action
      Person.Query.with_ongoing_interview()
      |> Epicenter.Repo.all()
      |> Cases.preload_lab_results()
      |> tids()
      |> assert_eq(~w{unassigned_first unassigned_last assigned_first assigned_middle assigned_last})
    end
  end

  describe "with_positive_lab_results" do
    test "filters for people with positive lab results, sorting by lab result sample date ascending" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      middle = Test.Fixtures.person_attrs(user, "middle", dob: ~D[2000-06-01], first_name: "Middle", last_name: "Testuser") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(middle, user, "middle-1", ~D[2020-06-03], result: "positive") |> Cases.create_lab_result!()

      last = Test.Fixtures.person_attrs(user, "last", dob: ~D[2000-06-01], first_name: "Last", last_name: "Testuser") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(last, user, "last-1", ~D[2020-06-04], result: "negative") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(last, user, "last-1", ~D[2020-06-05], result: "pOsItIvE") |> Cases.create_lab_result!()

      first = Test.Fixtures.person_attrs(user, "first", dob: ~D[2000-06-01], first_name: "First", last_name: "Testuser") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(first, user, "first-1", ~D[2020-06-02], result: "DeTectEd") |> Cases.create_lab_result!()

      missing =
        Test.Fixtures.person_attrs(user, "missing", dob: ~D[2000-06-01], first_name: "Missing Negative", last_name: "Testuser")
        |> Cases.create_person!()

      Test.Fixtures.lab_result_attrs(missing, user, "first-1", ~D[2020-06-02], result: "negative") |> Cases.create_lab_result!()

      Person.Query.with_positive_lab_results() |> Epicenter.Repo.all() |> tids() |> assert_eq(~w{first middle last})
    end

    test "excludes people without lab results" do
      user =
        Test.Fixtures.user_attrs(@admin, "user")
        |> Accounts.register_user!()

      Test.Fixtures.person_attrs(user, "with-lab-result")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs(user, "lab-result", ~D[2020-06-02])
      |> Cases.create_lab_result!()

      Test.Fixtures.person_attrs(user, "without-lab-result")
      |> Cases.create_person!()

      Person.Query.with_positive_lab_results()
      |> Epicenter.Repo.all()
      |> tids()
      |> assert_eq(~w{with-lab-result})
    end
  end

  describe "serializing for audit logs" do
    setup do
      person =
        Test.Fixtures.person_attrs(@admin, "old-positive-result")
        |> Cases.create_person!()

      person
      |> Test.Fixtures.lab_result_attrs(@admin, "old-positive-result", "09/18/2020", result: "positive")
      |> Cases.create_lab_result!()

      Test.Fixtures.email_attrs(@admin, person, "email")
      |> Cases.create_email!()

      Test.Fixtures.phone_attrs(@admin, person, "phone")
      |> Cases.create_phone!()

      person = Cases.get_person(person.id)
      [person: person]
    end

    test "with preloaded email/lab_result/phone", %{person: person} do
      person = person |> Cases.preload_phones() |> Cases.preload_emails() |> Cases.preload_lab_results()

      result = person |> Jason.encode!() |> Jason.decode!()

      person_id = person.id
      first_id = fn list -> Enum.at(list, 0).id end
      email_id = person.emails |> first_id.()
      phone_id = person.phones |> first_id.()
      lab_result_id = person.lab_results |> first_id.()

      assert %{
               "id" => ^person_id,
               "emails" => [
                 %{
                   "id" => ^email_id,
                   "address" => "email@example.com",
                   "delete" => nil,
                   "is_preferred" => nil,
                   "person_id" => ^person_id,
                   "tid" => "email"
                 }
               ],
               "lab_results" => [
                 %{
                   "id" => ^lab_result_id,
                   "person_id" => ^person_id,
                   "analyzed_on" => nil,
                   "reported_on" => nil,
                   "request_accession_number" => "accession-old-positive-result",
                   "request_facility_code" => "facility-old-positive-result",
                   "request_facility_name" => "old-positive-result Lab, Inc.",
                   "result" => "positive",
                   "sampled_on" => "2020-09-18",
                   "test_type" => nil,
                   "tid" => "old-positive-result"
                 }
               ],
               "phones" => [
                 %{
                   "id" => ^phone_id,
                   "number" => "1111111000",
                   "delete" => nil,
                   "is_preferred" => nil,
                   "person_id" => ^person_id,
                   "tid" => "phone",
                   "type" => "home"
                 }
               ]
             } = result
    end

    test "with nothing preloaded", %{person: person} do
      result_json = Jason.encode!(person)

      refute result_json =~ "emails"
      refute result_json =~ "lab_results"
      refute result_json =~ "phones"
    end
  end
end
