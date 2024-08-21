defmodule EpiViewpoint.Cases.PersonTest do
  use EpiViewpoint.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Demographic
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.Cases.Phone
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  setup do
    [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
  end

  describe "schema" do
    test "fields" do
      assert_schema(
        Person,
        [
          {:archived_at, :utc_datetime},
          {:archived_by_id, :binary_id},
          {:assigned_to_id, :binary_id},
          {:merged_at, :utc_datetime},
          {:merged_by_id, :binary_id},
          {:merged_into_id, :binary_id},
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
    setup %{user: user} do
      [alice: Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()]
    end

    test "can have zero lab_results", %{alice: alice} do
      alice |> Cases.preload_lab_results() |> Map.get(:lab_results) |> assert_eq([])
    end

    test "has many lab_results", %{alice: alice, user: user} do
      Test.Fixtures.lab_result_attrs(alice, user, "result1", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "result2", "06-02-2020") |> Cases.create_lab_result!()

      alice
      |> Cases.preload_lab_results()
      |> Map.get(:lab_results)
      |> tids()
      |> assert_eq(~w{result1 result2}, ignore_order: true)
    end

    test "has many case_investigations", %{alice: alice, user: user} do
      lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result1", ~D[2020-10-27]) |> Cases.create_lab_result!()
      Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation1") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation2") |> Cases.create_case_investigation!()

      alice
      |> Cases.preload_case_investigations()
      |> Map.get(:case_investigations)
      |> tids()
      |> assert_eq(~w{investigation1 investigation2}, ignore_order: true)
    end

    test "has many phone numbers", %{alice: alice, user: user} do
      Test.Fixtures.phone_attrs(user, alice, "phone-1", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(user, alice, "phone-2", number: "111-111-1001") |> Cases.create_phone!()

      assert alice |> Cases.preload_phones() |> Map.get(:phones) |> tids() == ~w{phone-1 phone-2}
    end

    test "has many email addresses", %{alice: alice, user: user} do
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
      person = %Person{demographics: [%{source: "form", first_name: "Ally"}]}
      changeset = Person.changeset(person, %{"form_demographic" => %{first_name: "Bill"}})
      assert {:ok, %{demographics: [%{source: "form", first_name: "Bill"}]}} = apply_action(changeset, :test)
    end

    # The caller must choose whether they are replacing the demographics, or additively changing them
    test "setting demographics and form_demographic at the same time is not supported" do
      person = %Person{demographics: [%Demographic{source: "form", first_name: "Ally"}]}

      assert catch_throw(
               Person.changeset(person, %{"demographics" => [%{source: "form", first_name: "Ally2"}], "form_demographic" => %{first_name: "Bill"}})
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
      person = %Person{phones: [%Phone{number: "1111111000"}]}
      changeset = Person.changeset(person, %{"additive_phone" => %{number: "1111111002", source: "blah"}})
      assert {:ok, %{phones: [%{number: "1111111000"}, %{source: "blah", number: "1111111002"}]}} = apply_action(changeset, :test)
    end

    test "additively inserting a phone number when the phone number already exists" do
      person = %Person{phones: [%Phone{number: "1111111000"}]}
      changeset = Person.changeset(person, %{"additive_phone" => %{number: "1111111000", source: "blah"}})
      assert {:ok, %{phones: [%{number: "1111111000"}]}} = apply_action(changeset, :test)
    end

    test "additively inserting a phone number when the key is an atom" do
      person = %Person{phones: [%Phone{number: "1111111000"}]}
      changeset = Person.changeset(person, %{:additive_phone => %{number: "1111111002", source: "blah"}})
      assert {:ok, %{phones: [%{number: "1111111000"}, %{source: "blah", number: "1111111002"}]}} = apply_action(changeset, :test)
    end

    # The caller must choose whether they are replacing the phones, or additively changing them
    test "setting phones and additive_phone at the same time is not supported" do
      person = %Person{phones: [%Phone{number: "1111111000"}]}
      assert catch_throw(Person.changeset(person, %{:phones => [], :additive_phone => %{number: "1111111002", source: "blah"}}))
    end

    test "associations - address" do
      address_changeset =
        new_changeset(%{addresses: [%{street: "1023 Test St", city: "City7", state: "ZB", postal_code: "00002"}]}).changes.addresses
        |> Euclid.Extra.List.first()

      assert %{street: "1023 Test St", city: "City7", state: "ZB", postal_code: "00002"} = address_changeset.changes
    end

    test "archiving" do
      originator = Test.Fixtures.user_attrs(@admin, "originator") |> Accounts.register_user!()
      originator_id = originator.id
      person = %Person{tid: "archived-person"}
      archiving_changeset = Person.changeset(person, %{archived_at: ~U[2020-10-31 23:03:07Z], archived_by_id: originator_id})

      assert %{archived_at: ~U[2020-10-31 23:03:07Z], archived_by_id: ^originator_id} = archiving_changeset.changes
    end
  end

  describe "changeset_for_archive" do
    test "creates a changeset that will archive the person", %{user: user} do
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      %Ecto.Changeset{} = changeset = Person.changeset_for_archive(person, user)
      assert changeset.changes.archived_by_id == user.id
      assert_recent(changeset.changes.archived_at)
    end
  end

  describe "latest_case_investigation" do
    test "returns nil if no lab results", %{user: user} do
      user
      |> Test.Fixtures.person_attrs("alice")
      |> Cases.create_person!()
      |> Cases.preload_case_investigations()
      |> Person.latest_case_investigation()
      |> assert_eq(nil)
    end

    test "returns the case investigation with the most recent created at date", %{user: user} do
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

  describe "latest_contact_investigation" do
    setup %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
      case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation") |> Cases.create_case_investigation!()

      {:ok, contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("contact_investigation", %{exposing_case_id: case_investigation.id}),
         Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      contact_investigation = ContactInvestigations.get(contact_investigation.id, user) |> ContactInvestigations.preload_exposed_person()
      exposed_person = contact_investigation.exposed_person |> Cases.preload_contact_investigations(user)

      {:ok, second_contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("second_contact_investigation", %{
           exposing_case_id: exposed_person.contact_investigations |> List.first() |> Map.get(:exposing_case_id),
           interview_started_at: ~U[2020-10-31 23:03:07Z]
         }), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      second_contact_investigation
      |> Ecto.Changeset.change(exposed_person_id: exposed_person.id)
      |> Repo.update!()

      [exposed_person: Cases.get_person(exposed_person.id, @admin)]
    end

    test "returns the contact investigation with the most recent created at date", %{exposed_person: exposed_person, user: user} do
      assert exposed_person
             |> Cases.preload_contact_investigations(user)
             |> Person.latest_contact_investigation()
             |> Map.get(:tid) == "second_contact_investigation"
    end
  end

  describe "coalesce_demographics" do
    test "prioritizes new manual data > old manual data > old import data > new import data" do
      older_manual_attrs = %{dob: nil, first_name: "Older-Manual", source: "form", seq: 1}
      newer_manual_attrs = %{dob: nil, first_name: "Newer-Manual", source: "form", seq: 2}
      older_import_attrs = %{dob: ~D[2000-03-01], first_name: "Older-Import", source: "import", seq: 3}
      newer_import_attrs = %{dob: ~D[2000-04-01], first_name: "Newer-Import", source: "import", last_name: "Testuser", seq: 4}

      person = %{demographics: [newer_import_attrs, older_import_attrs, older_manual_attrs, newer_manual_attrs]}

      coalesced_demographics = person |> Person.coalesce_demographics()

      assert coalesced_demographics.dob == older_import_attrs.dob
      assert coalesced_demographics.first_name == newer_manual_attrs.first_name
      assert coalesced_demographics.last_name == newer_import_attrs.last_name
    end
  end

  describe "serializing for audit logs" do
    setup do
      person = Test.Fixtures.person_attrs(@admin, "old-positive-result") |> Cases.create_person!()
      person |> Test.Fixtures.lab_result_attrs(@admin, "old-positive-result", "09/18/2020", result: "positive") |> Cases.create_lab_result!()
      Test.Fixtures.email_attrs(@admin, person, "email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(@admin, person, "phone") |> Cases.create_phone!()
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

  # # # Query

  describe "all" do
    test "sorts by creation order", %{user: user} do
      Test.Fixtures.person_attrs(user, "first", dob: ~D{2000-06-01}, first_name: "Alice", last_name: "Testuser") |> Cases.create_person!()
      Test.Fixtures.person_attrs(user, "middle", dob: ~D{2000-06-01}, first_name: "Billy", last_name: "Testuser") |> Cases.create_person!()
      Test.Fixtures.person_attrs(user, "last", dob: ~D{2000-07-01}, first_name: "Alice", last_name: "Testuser") |> Cases.create_person!()

      Person.Query.all() |> EpiViewpoint.Repo.all() |> tids() |> assert_eq(~w{first middle last})
    end
  end
end
