defmodule Epicenter.CasesTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1, pluck: 2]

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Import.ImportInfo
  alias Epicenter.Extra
  alias Epicenter.Test

  describe "importing" do
    test "import_lab_results imports lab results and creates lab_result and person records" do
      originator = Test.Fixtures.user_attrs("originator") |> Accounts.create_user!()

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

      Cases.list_people() |> Enum.map(& &1.first_name) |> assert_eq(["Alice", "Billy"], ignore_order: true)
      Cases.list_lab_results() |> Enum.map(& &1.result) |> assert_eq(["positive", "negative"], ignore_order: true)
    end
  end

  describe "lab results" do
    test "create_lab_result! creates a lab result" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, "result1", "06-01-2020") |> Cases.create_lab_result!()

      assert lab_result.request_accession_number == "accession-result1"
      assert lab_result.request_facility_code == "facility-result1"
      assert lab_result.request_facility_name == "result1 Lab, Inc."
      assert lab_result.result == "positive"
      assert lab_result.sampled_on == ~D[2020-06-01]
      assert lab_result.tid == "result1"
    end

    test "list_lab_results sorts by sample date" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

      Test.Fixtures.lab_result_attrs(person, "newer", "06-03-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(person, "older", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(person, "middle", "06-02-2020") |> Cases.create_lab_result!()

      Cases.list_lab_results() |> tids() |> assert_eq(~w{older middle newer})
    end
  end

  describe "people" do
    test "create_person! creates a person" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

      assert person.dob == ~D[2000-01-01]
      assert person.first_name == "Alice"
      assert person.last_name == "Testuser"
      assert person.tid == "alice"
      assert person.fingerprint == "2000-01-01 alice testuser"

      assert_versioned(person)
    end

    test "create_person creates a person" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      {:ok, person} = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person()
      assert person.fingerprint == "2000-01-01 alice testuser"
      assert_versioned(person)
    end

    test "get_people" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Cases.get_people([alice.id]) |> tids() |> assert_eq(["alice"])
    end

    test "get_person" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      fetched = Cases.get_person(person.id)
      assert fetched.tid == "alice"
    end

    test "list_people" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()

      Test.Fixtures.person_attrs(user, "middle", dob: ~D[2000-06-01], first_name: "Alice", last_name: "Testuser")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs("middle-1", ~D[2020-06-03])
      |> Cases.create_lab_result!()

      Test.Fixtures.person_attrs(user, "last", dob: ~D[2000-06-01], first_name: "Billy", last_name: "Testuser")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs("last-1", Extra.Date.days_ago(4))
      |> Cases.create_lab_result!()

      Test.Fixtures.person_attrs(user, "first", dob: ~D[2000-07-01], first_name: "Alice", last_name: "Testuser")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs("first-1", ~D[2020-06-02])
      |> Cases.create_lab_result!()

      Cases.list_people() |> tids() |> assert_eq(~w{first middle last})
      Cases.list_people(:all) |> tids() |> assert_eq(~w{first middle last})
      Cases.list_people(:call_list) |> tids() |> assert_eq(~w{last})
      Cases.list_people(:with_lab_results) |> tids() |> assert_eq(~w{first middle last})
    end

    test "assign_user_to_people updates people's assigned user" do
      creator = Test.Fixtures.user_attrs("creator") |> Accounts.create_user!()
      updater = Test.Fixtures.user_attrs("updater") |> Accounts.create_user!()

      assigned_to_user = Test.Fixtures.user_attrs("assigned-to") |> Accounts.create_user!()
      alice = Test.Fixtures.person_attrs(creator, "alice") |> Cases.create_person!()
      bobby = Test.Fixtures.person_attrs(creator, "bobby") |> Cases.create_person!()

      {:ok, [updated_alice]} = Cases.assign_user_to_people(user_id: assigned_to_user.id, people_ids: [alice.id], originator: updater)

      assert updated_alice |> Repo.preload(:assigned_to) |> Map.get(:assigned_to) |> Map.get(:tid) == "assigned-to"
      assert updated_alice.assigned_to.tid == "assigned-to"

      assert_last_version(updated_alice,
        change: %{"assigned_to_id" => assigned_to_user.id, "originator" => %{"id" => updater.id}},
        by: "updater"
      )

      assert bobby |> Repo.preload(:assigned_to) |> Map.get(:assigned_to) == nil
    end

    test "update_person updates a person" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "versioned", first_name: "version-1") |> Cases.create_person!()
      {:ok, updated_person} = person |> Cases.update_person(%{first_name: "version-2"})

      assert updated_person.first_name == "version-2"
      assert_versioned(updated_person, expected_count: 2)

      {:ok, updated_person} = person |> Cases.update_person(%{first_name: "version-3"})
      assert_versioned(updated_person, expected_count: 3)
    end

    test "upsert_person! creates a person if one doesn't exist (based on first name, last name, dob)" do
      creator = Test.Fixtures.user_attrs("creator") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(creator, "alice", external_id: "10000") |> Cases.upsert_person!()

      assert person.dob == ~D[2000-01-01]
      assert person.first_name == "Alice"
      assert person.last_name == "Testuser"
      assert person.tid == "alice"

      assert_versions(person, [
        [
          change: %{
            "assigned_to_id" => nil,
            "dob" => "2000-01-01",
            "external_id" => "10000",
            "fingerprint" => "2000-01-01 alice testuser",
            "first_name" => "Alice",
            "last_name" => "Testuser",
            "originator" => %{"id" => creator.id},
            "preferred_language" => "English",
            "tid" => "alice"
          },
          by: "creator"
        ]
      ])
    end

    test "upsert_person! updates a person if one already exists (based on first name, last name, dob)" do
      creator = Test.Fixtures.user_attrs("creator") |> Accounts.create_user!()
      Test.Fixtures.person_attrs(creator, "alice", tid: "first-insert") |> Cases.upsert_person!()

      updater = Test.Fixtures.user_attrs("updater") |> Accounts.create_user!()
      Test.Fixtures.person_attrs(updater, "alice", tid: "second-insert") |> Cases.upsert_person!()

      assert [person] = Cases.list_people()

      assert person.dob == ~D[2000-01-01]
      assert person.first_name == "Alice"
      assert person.last_name == "Testuser"
      assert person.tid == "second-insert"
    end
  end

  describe "upsert_phone!" do
    setup do
      creator = Test.Fixtures.user_attrs("creator") |> Accounts.create_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()

      %{creator: creator, person: person}
    end

    defp add_phone_for_person(tid, person) do
      original_phone = Test.Fixtures.phone_attrs(person, tid, %{}) |> Cases.create_phone!()
      {:ok, sql_safe_id} = Ecto.UUID.dump(original_phone.id)

      Ecto.Adapters.SQL.query!(
        Epicenter.Repo,
        "UPDATE phones SET updated_at = $1 WHERE id = $2",
        [~U[1970-01-01 10:30:00Z], sql_safe_id]
      )

      original_phone
    end

    test "when the phone number already exists for the same person", %{person: person} do
      original_phone = add_phone_for_person("phone1", person)

      assert Cases.get_phone(original_phone.id).updated_at == ~N[1970-01-01 10:30:00Z]

      Cases.upsert_phone!(%{person_id: person.id, tid: "phone2", number: original_phone.number})

      person = Cases.preload_phones(person)
      assert person.phones |> tids == ["phone1"]
      assert person.phones |> pluck(:updated_at) != ~N[1970-01-01 10:30:00Z]
    end

    test "when the phone number already exists for a different person", %{creator: creator, person: person} do
      {:ok, other_person} = Test.Fixtures.person_attrs(creator, "person2") |> Cases.create_person()
      other_persons_phone = add_phone_for_person("phone3", other_person)

      Cases.upsert_phone!(%{person_id: person.id, tid: "phone2", number: other_persons_phone.number})

      other_person = Cases.preload_phones(other_person)
      assert other_person.phones |> tids == ["phone3"]
      person = Cases.preload_phones(person)
      assert person.phones |> tids == ["phone2"]
    end

    test "when the phone number does not yet exist", %{person: person} do
      phone_attrs = Test.Fixtures.phone_attrs(person, "", %{})
      Cases.upsert_phone!(%{person_id: person.id, tid: "phone2", number: phone_attrs.number})

      person = Cases.preload_phones(person)
      assert person.phones |> tids == ["phone2"]
    end
  end

  describe "upsert_address!" do
    setup do
      creator = Test.Fixtures.user_attrs("creator") |> Accounts.create_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()

      %{creator: creator, person: person}
    end

    test "when the address already exists for the same person", %{person: person} do
      original_address = Test.Fixtures.address_attrs(person, "address1", 4250) |> Cases.create_address!()

      {:ok, sql_safe_id} = Ecto.UUID.dump(original_address.id)
      Ecto.Adapters.SQL.query!(Epicenter.Repo, "UPDATE addresses SET updated_at = $1 WHERE id = $2", [~N[1970-01-01 10:30:00Z], sql_safe_id])

      Cases.upsert_address!(Map.from_struct(%{original_address | tid: "address2"}))

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(person)
      assert length(addresses) == 1
      assert hd(addresses).updated_at != ~N[1970-01-01 10:30:00Z]
    end

    test "when the address already exists for a different person", %{creator: creator, person: person} do
      {:ok, other_person} = Test.Fixtures.person_attrs(creator, "other person") |> Cases.create_person()
      original_address = Test.Fixtures.address_attrs(other_person, "other address", 4250) |> Cases.create_address!()

      Cases.upsert_address!(Map.from_struct(%{original_address | tid: "address2", person_id: person.id}))

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(person)
      assert hd(addresses).tid == "address2"

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(other_person)
      assert hd(addresses).tid == "other address"
    end

    test "when the address does not yet exist", %{person: person} do
      original_address = Test.Fixtures.address_attrs(person, "address1", 4250) |> Cases.create_address!()

      Cases.upsert_address!(Map.from_struct(original_address))

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(person)
      assert length(addresses) == 1
      assert hd(addresses).tid == "address1"
    end
  end
end
