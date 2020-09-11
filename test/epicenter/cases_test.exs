defmodule Epicenter.CasesTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Import.ImportInfo
  alias Epicenter.Extra
  alias Epicenter.Test

  describe "importing" do
    test "import_lab_results imports lab results and creates lab_result and person records" do
      originator = Test.Fixtures.user_attrs("originator") |> Accounts.create_user!()

      """
      first_name , last_name , dob        , sample_date , result_date , result
      Alice      , Testuser  , 01/01/1970 , 06/01/2020  , 06/03/2020  , positive
      Billy      , Testuser  , 03/01/1990 , 06/06/2020  , 06/07/2020  , negative
      """
      |> Cases.import_lab_results(originator)
      |> assert_eq(
        {:ok,
         %ImportInfo{
           imported_lab_result_count: 2,
           imported_person_count: 2,
           total_lab_result_count: 2,
           total_person_count: 2
         }}
      )

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

    test "update_assignment updates a person's assigned user" do
      creator = Test.Fixtures.user_attrs("creator") |> Accounts.create_user!()
      assigned_to_user = Test.Fixtures.user_attrs("assigned-to") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(creator, "alice") |> Cases.create_person!()
      {:ok, updated_person} = person |> Cases.update_assignment(assigned_to_user)

      updated_person |> Repo.preload(:assigned_to) |> Map.get(:assigned_to) |> Map.get(:tid) |> assert_eq("assigned-to")
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
end
