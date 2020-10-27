defmodule Epicenter.CasesTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1, pluck: 2]

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Import.ImportInfo
  alias Epicenter.Extra
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()
  describe "importing" do
    defp first_names() do
      Cases.list_people() |> Cases.preload_demographics() |> Enum.map(&(&1.demographics |> List.first() |> Map.get(:first_name)))
    end

    test "import_lab_results imports lab results and creates lab_result and person records" do
      originator = Test.Fixtures.user_attrs(@admin, "originator") |> Accounts.register_user!()

      {:ok,
       %ImportInfo{
         imported_people: people,
         imported_lab_result_count: 2,
         imported_person_count: 2,
         total_lab_result_count: 2,
         total_person_count: 2
       }} =
        %{
          file_name: "test.csv",
          contents: """
          search_firstname_2 , search_lastname_1 , dateofbirth_8 , datecollected_36 , resultdate_42 , result_39 , person_tid
          Alice              , Testuser          , 01/01/1970    , 06/01/2020       , 06/03/2020    , positive  , alice
          Billy              , Testuser          , 03/01/1990    , 06/06/2020       , 06/07/2020    , negative  , billy
          """
        }
        |> Cases.import_lab_results(originator)

      assert people |> tids() == ["alice", "billy"]

      first_names() |> assert_eq(["Alice", "Billy"], ignore_order: true)
      Cases.list_lab_results() |> Enum.map(& &1.result) |> assert_eq(["positive", "negative"], ignore_order: true)
    end
  end

  describe "lab results" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      %{creator: creator}
    end

    setup [:make_person]
    defp make_person(%{with_person: true, creator: creator}), do: [person: Test.Fixtures.person_attrs(creator, "alice") |> Cases.create_person!()]
    defp make_person(_), do: :ok

    @tag with_person: true
    test "create_lab_result! creates a lab result", %{creator: creator, person: person} do
      lab_result = Test.Fixtures.lab_result_attrs(person, creator, "result1", "06-01-2020") |> Cases.create_lab_result!()

      assert lab_result.request_accession_number == "accession-result1"
      assert lab_result.request_facility_code == "facility-result1"
      assert lab_result.request_facility_name == "result1 Lab, Inc."
      assert lab_result.result == "positive"
      assert lab_result.sampled_on == ~D[2020-06-01]
      assert lab_result.tid == "result1"
    end

    @tag with_person: true
    test "create_lab_result! results in a correct revision count", %{creator: creator, person: person} do
      lab_result = Test.Fixtures.lab_result_attrs(person, creator, "result1", "06-01-2020") |> Cases.create_lab_result!()

      assert_revision_count(lab_result, 1)
    end

    @tag with_person: true
    test "create_lab_result! results in a correct audit log", %{person: person, creator: creator} do
      lab_result = Test.Fixtures.lab_result_attrs(person, creator, "result1", "06-01-2020") |> Cases.create_lab_result!()

      assert_recent_audit_log(lab_result, creator, %{
        "person_id" => person.id,
        "request_accession_number" => "accession-result1",
        "request_facility_code" => "facility-result1",
        "request_facility_name" => "result1 Lab, Inc.",
        "result" => "positive",
        "sampled_on" => "2020-06-01",
        "tid" => "result1"
      })
    end

    @tag with_person: true
    test "list_lab_results sorts by sample date", %{person: person, creator: creator} do
      Test.Fixtures.lab_result_attrs(person, creator, "newer", "06-03-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(person, creator, "older", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(person, creator, "middle", "06-02-2020") |> Cases.create_lab_result!()

      Cases.list_lab_results() |> tids() |> assert_eq(~w{older middle newer})
    end

    test "upsert_lab_result! creates a lab result if one doesn't exist (based on person_id and all lab result fields)" do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      person_1 = Test.Fixtures.person_attrs(creator, "person-1") |> Cases.create_person!()
      person_2 = Test.Fixtures.person_attrs(creator, "person-2") |> Cases.create_person!()

      update_first_elem = fn {first, second}, func -> {func.(first), second} end

      Test.Fixtures.lab_result_attrs(person_1, creator, "result-1", "01/01/2020")
      |> update_first_elem.(&Map.put(&1, :tid, "person-1-result-1"))
      |> Cases.upsert_lab_result!()

      Test.Fixtures.lab_result_attrs(person_1, creator, "result-2", "01/01/2020")
      |> update_first_elem.(&Map.put(&1, :tid, "person-1-result-2"))
      |> Cases.upsert_lab_result!()

      Test.Fixtures.lab_result_attrs(person_1, creator, "result-2", "01/01/2020")
      |> update_first_elem.(&Map.put(&1, :tid, "person-1-result-2-dupe"))
      |> Cases.upsert_lab_result!()

      Test.Fixtures.lab_result_attrs(person_2, creator, "result-2", "01/01/2020")
      |> update_first_elem.(&Map.put(&1, :tid, "person-2-result-2"))
      |> Cases.upsert_lab_result!()

      [person_1 = %{tid: "person-1"}, person_2 = %{tid: "person-2"}] =
        Cases.list_people(:all)
        |> Enum.map(&Cases.preload_lab_results/1)

      assert person_1.lab_results |> tids() == ~w{person-1-result-1 person-1-result-2}
      assert person_2.lab_results |> tids() == ~w{person-2-result-2}

      lab_result = person_1.lab_results |> Enum.at(1)

      assert_revision_count(lab_result, 2)

      assert_recent_audit_log(lab_result, creator, %{
        "person_id" => person_1.id,
        "request_accession_number" => "accession-result-2",
        "request_facility_code" => "facility-result-2",
        "request_facility_name" => "result-2 Lab, Inc.",
        "result" => "positive",
        "sampled_on" => "2020-01-01",
        "tid" => "person-1-result-2-dupe"
      })
    end
  end

  describe "people" do
    test "create_person! creates a person" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.preload_demographics()

      assert person.tid == "alice"
      [person_demographics] = person.demographics
      assert person_demographics.dob == ~D[2000-01-01]
      assert person_demographics.first_name == "Alice"
      assert person_demographics.last_name == "Testuser"

      assert_revision_count(person, 1)

      assert %{
               "demographics" => [
                 %{
                   "dob" => "2000-01-01",
                   "first_name" => "Alice",
                   "last_name" => "Testuser",
                   "preferred_language" => "English"
                 }
               ],
               "tid" => "alice"
             } = recent_audit_log(person).change
    end

    test "create_person creates a person" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person()

      assert_revision_count(person, 1)

      assert %{
               "demographics" => [
                 %{
                   "dob" => "2000-01-01",
                   "first_name" => "Alice",
                   "last_name" => "Testuser",
                   "preferred_language" => "English"
                 }
               ],
               "tid" => "alice"
             } = recent_audit_log(person).change
    end

    test "get_people" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Cases.get_people([alice.id]) |> tids() |> assert_eq(["alice"])
    end

    test "get_person" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      fetched = Cases.get_person(person.id)
      assert fetched.tid == "alice"
    end

    test "list_people" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      Test.Fixtures.person_attrs(user, "first", dob: ~D[2000-06-01], first_name: "Alice", last_name: "Testuser")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs(user, "first-1", ~D[2020-06-02])
      |> Cases.create_lab_result!()

      Test.Fixtures.person_attrs(user, "middle", dob: ~D[2000-06-01], first_name: "Billy", last_name: "Testuser")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs(user, "middle-1", ~D[2020-06-03])
      |> Cases.create_lab_result!()

      Test.Fixtures.person_attrs(user, "last", dob: ~D[2000-07-01], first_name: "Alice", last_name: "Testuser")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs(user, "last-1", Extra.Date.days_ago(4))
      |> Cases.create_lab_result!()

      Cases.list_people() |> tids() |> assert_eq(~w{first middle last})
      Cases.list_people(:all) |> tids() |> assert_eq(~w{first middle last})
      Cases.list_people(:call_list) |> tids() |> assert_eq(~w{last})
      Cases.list_people(:with_lab_results) |> tids() |> assert_eq(~w{first middle last})
    end

    test "assign_user_to_people updates people's assigned user" do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      updater = Test.Fixtures.user_attrs(@admin, "updater") |> Accounts.register_user!()

      assigned_to_user = Test.Fixtures.user_attrs(@admin, "assigned-to") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(creator, "alice") |> Cases.create_person!()
      bobby = Test.Fixtures.person_attrs(creator, "bobby") |> Cases.create_person!()

      {:ok, [updated_alice]} =
        Cases.assign_user_to_people(
          user_id: assigned_to_user.id,
          people_ids: [alice.id],
          audit_meta: Test.Fixtures.audit_meta(updater)
        )

      assert updated_alice |> Repo.preload(:assigned_to) |> Map.get(:assigned_to) |> Map.get(:tid) == "assigned-to"
      assert updated_alice.assigned_to.tid == "assigned-to"

      assert_revision_count(updated_alice, 2)

      assert_recent_audit_log(
        updated_alice,
        updater,
        %{"assigned_to_id" => assigned_to_user.id}
      )

      assert bobby |> Repo.preload(:assigned_to) |> Map.get(:assigned_to) == nil
    end

    test "update_person updates a person" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      person =
        Test.Fixtures.person_attrs(user, "versioned") |> Test.Fixtures.add_demographic_attrs(%{first_name: "version-1"}) |> Cases.create_person!()

      [%{id: demographic_id}] = person.demographics

      {:ok, updated_person} =
        person |> Cases.update_person({%{demographics: [%{id: demographic_id, first_name: "version-2"}]}, Test.Fixtures.audit_meta(user)})

      updated_person = updated_person |> Cases.preload_demographics()
      assert Person.coalesce_demographics(updated_person).first_name == "version-2"

      assert_revision_count(person, 2)

      assert %{
               "demographics" => [
                 %{
                   "id" => ^demographic_id,
                   "first_name" => "version-2"
                 }
               ]
             } = recent_audit_log(person).change
    end

    test "find_matching_person finds a person by their dob, first_name, and last_name" do
      dob = ~D[2000-01-01]
      strip_seq = fn map -> Map.put(map, :seq, nil) end
      person = Test.Fixtures.person_attrs(@admin, "alice", dob: dob) |> Cases.create_person!() |> strip_seq.()

      match = Cases.find_matching_person(%{"first_name" => "Alice", "last_name" => "Testuser", "dob" => dob})

      assert match.id == person.id

      refute Cases.find_matching_person(%{"first_name" => "billy", "last_name" => "Testuser", "dob" => dob})
      refute Cases.find_matching_person(%{"first_name" => "Alice", "last_name" => "Testy", "dob" => dob})
      refute Cases.find_matching_person(%{"first_name" => "Alice", "last_name" => "Testuser", "dob" => ~D[2000-01-02]})
    end

    test "find_or_create_demographic/2" do
      person = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()

      Cases.find_or_create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "alice", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})
      Cases.find_or_create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "alice", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})
      Cases.find_or_create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "alice", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})
      Cases.find_or_create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "alice", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})
      Cases.find_or_create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "alice", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})
      Cases.find_or_create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "alice", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})
      Cases.find_or_create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "alice", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})
      Cases.find_or_create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "alice", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})
      assert person |> Cases.preload_demographics() |> Map.get(:demographics) |> length() == 1
    end
  end

  describe "create_phone!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()

      %{creator: creator, person: person}
    end

    test "persists the values correctly", %{person: person, creator: creator} do
      phone = Test.Fixtures.phone_attrs(creator, person, "phone1", %{}) |> Cases.create_phone!()

      assert phone.number == "1111111000"
      assert phone.person_id == person.id
      assert phone.type == "home"
      assert phone.tid == "phone1"
    end

    test "has a revision count", %{person: person, creator: creator} do
      phone = Test.Fixtures.phone_attrs(creator, person, "phone1", %{}) |> Cases.create_phone!()

      assert_revision_count(phone, 1)
    end

    test "has an audit log", %{person: person, creator: creator} do
      phone = Test.Fixtures.phone_attrs(creator, person, "phone1", %{}) |> Cases.create_phone!()

      assert_recent_audit_log(phone, creator, %{
        "tid" => "phone1",
        "number" => "1111111000",
        "person_id" => person.id,
        "type" => "home"
      })
    end
  end

  describe "upsert_phone!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()

      %{creator: creator, person: person}
    end

    defp add_phone_for_person(tid, person, creator) do
      original_phone = Test.Fixtures.phone_attrs(creator, person, tid, %{}) |> Cases.create_phone!()
      {:ok, sql_safe_id} = Ecto.UUID.dump(original_phone.id)

      Ecto.Adapters.SQL.query!(
        Epicenter.Repo,
        "UPDATE phones SET updated_at = $1 WHERE id = $2",
        [~U[1970-01-01 10:30:00Z], sql_safe_id]
      )

      original_phone
    end

    test "when the phone number already exists for the same person", %{person: person, creator: creator} do
      original_phone = add_phone_for_person("phone1", person, creator)

      assert Cases.get_phone(original_phone.id).updated_at == ~U[1970-01-01 10:30:00Z]

      phone = Test.Fixtures.phone_attrs(creator, person, "phone2", %{number: original_phone.number}) |> Cases.upsert_phone!()

      person = Cases.preload_phones(person)
      assert person.phones |> tids == ["phone1"]
      assert person.phones |> pluck(:updated_at) != ~N[1970-01-01 10:30:00Z]

      assert_revision_count(phone, 2)

      assert_recent_audit_log(phone, creator, %{
        "tid" => "phone2",
        "number" => "1111111000",
        "person_id" => person.id,
        "type" => "home"
      })
    end

    test "when the phone number already exists for a different person", %{creator: creator, person: person} do
      {:ok, other_person} = Test.Fixtures.person_attrs(creator, "person2") |> Cases.create_person()
      other_persons_phone = add_phone_for_person("phone3", other_person, creator)

      phone = Test.Fixtures.phone_attrs(creator, person, "phone2", %{number: other_persons_phone.number}) |> Cases.upsert_phone!()

      other_person = Cases.preload_phones(other_person)
      assert other_person.phones |> tids == ["phone3"]
      person = Cases.preload_phones(person)
      assert person.phones |> tids == ["phone2"]

      assert_revision_count(phone, 1)

      assert_recent_audit_log(phone, creator, %{
        "tid" => "phone2",
        "number" => "1111111000",
        "person_id" => person.id,
        "type" => "home"
      })
    end

    test "when the phone number does not yet exist", %{creator: creator, person: person} do
      assert Cases.preload_phones(person).phones == []
      phone = Test.Fixtures.phone_attrs(creator, person, "phone2", %{}) |> Cases.upsert_phone!()

      person = Cases.preload_phones(person)
      assert person.phones |> tids == ["phone2"]

      assert_revision_count(phone, 1)

      assert_recent_audit_log(phone, creator, %{
        "tid" => "phone2",
        "number" => "1111111000",
        "person_id" => person.id,
        "type" => "home"
      })
    end
  end

  describe "create_address!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()
      audit_meta = Test.Fixtures.audit_meta(creator)

      %{creator: creator, person: person, audit_meta: audit_meta}
    end

    test "persists the values correctly", %{creator: creator, person: person} do
      address = Test.Fixtures.address_attrs(creator, person, "address1", 4250) |> Cases.create_address!()

      assert address.street == "4250 Test St"
      assert address.city == "City"
      assert address.state == "OH"
      assert address.postal_code == "00000"
      assert address.type == "home"
      assert address.tid == "address1"
      assert address.person_id == person.id
    end

    test "has a revision count", %{creator: creator, person: person} do
      address = Test.Fixtures.address_attrs(creator, person, "address1", 4250) |> Cases.create_address!()

      assert_revision_count(address, 1)
    end

    test "has an audit log", %{creator: creator, person: person} do
      address = Test.Fixtures.address_attrs(creator, person, "address1", 4250) |> Cases.create_address!()

      assert_recent_audit_log(address, creator, %{
        "tid" => "address1",
        "street" => "4250 Test St",
        "city" => "City",
        "state" => "OH",
        "postal_code" => "00000",
        "person_id" => person.id,
        "type" => "home"
      })
    end
  end

  describe "upsert_address!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()
      audit_meta = Test.Fixtures.audit_meta(creator)

      %{creator: creator, person: person, audit_meta: audit_meta}
    end

    test "when the address already exists for the same person", %{creator: creator, person: person, audit_meta: audit_meta} do
      original_address = Test.Fixtures.address_attrs(creator, person, "address1", 4250) |> Cases.create_address!()

      {:ok, sql_safe_id} = Ecto.UUID.dump(original_address.id)
      Ecto.Adapters.SQL.query!(Epicenter.Repo, "UPDATE addresses SET updated_at = $1 WHERE id = $2", [~N[1970-01-01 10:30:00Z], sql_safe_id])

      Cases.upsert_address!({Map.from_struct(%{original_address | tid: "address2"}), audit_meta})

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(person)
      assert length(addresses) == 1
      assert hd(addresses).updated_at != ~N[1970-01-01 10:30:00Z]

      assert_revision_count(original_address, 2)

      assert_recent_audit_log(original_address, creator, %{
        "tid" => "address2",
        "street" => "4250 Test St",
        "city" => "City",
        "state" => "OH",
        "postal_code" => "00000",
        "person_id" => person.id,
        "type" => "home"
      })
    end

    test "when the address already exists for a different person", %{creator: creator, person: person, audit_meta: audit_meta} do
      {:ok, other_person} = Test.Fixtures.person_attrs(creator, "other person") |> Cases.create_person()
      original_address = Test.Fixtures.address_attrs(creator, other_person, "other address", 4250) |> Cases.create_address!()

      new_address = Cases.upsert_address!({Map.from_struct(%{original_address | tid: "address2", person_id: person.id}), audit_meta})

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(person)
      assert hd(addresses).tid == "address2"

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(other_person)
      assert hd(addresses).tid == "other address"

      assert_revision_count(new_address, 1)

      assert_recent_audit_log(new_address, creator, %{
        "tid" => "address2",
        "street" => "4250 Test St",
        "city" => "City",
        "state" => "OH",
        "postal_code" => "00000",
        "person_id" => person.id,
        "type" => "home"
      })
    end

    test "when the address does not yet exist", %{person: person, creator: creator} do
      new_address = Cases.upsert_address!(Test.Fixtures.address_attrs(creator, person, "address1", 4250))

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(person)
      assert length(addresses) == 1
      assert hd(addresses).tid == "address1"

      assert_revision_count(new_address, 1)

      assert_recent_audit_log(new_address, creator, %{
        "tid" => "address1",
        "street" => "4250 Test St",
        "city" => "City",
        "state" => "OH",
        "postal_code" => "00000",
        "person_id" => person.id,
        "type" => "home"
      })
    end
  end
end
