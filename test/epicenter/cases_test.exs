defmodule Epicenter.CasesTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.Import.ImportInfo
  alias Epicenter.Extra
  alias Epicenter.Test
  alias Epicenter.Version

  describe "importing" do
    test "import_lab_results imports lab results and creates lab_result and person records" do
      """
      first_name , last_name , dob        , sample_date , result_date , result
      Alice      , Ant       , 01/02/1970 , 06/01/2020  , 06/03/2020  , positive
      Billy      , Bat       , 03/04/1990 , 06/06/2020  , 06/07/2020  , negative
      """
      |> Cases.import_lab_results()
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
      person = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, "result1", "06-01-2020") |> Cases.create_lab_result!()

      assert lab_result.request_accession_number == "accession-result1"
      assert lab_result.request_facility_code == "facility-result1"
      assert lab_result.request_facility_name == "result1 Lab, Inc."
      assert lab_result.result == "positive"
      assert lab_result.sample_date == ~D[2020-06-01]
      assert lab_result.tid == "result1"
    end

    test "list_lab_results sorts by sample date" do
      person = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person!()

      Test.Fixtures.lab_result_attrs(person, "newer", "06-03-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(person, "older", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(person, "middle", "06-02-2020") |> Cases.create_lab_result!()

      Cases.list_lab_results() |> tids() |> assert_eq(~w{older middle newer})
    end
  end

  describe "people" do
    test "create_person! creates a person" do
      person = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person!()

      assert person.dob == ~D[2000-01-01]
      assert person.first_name == "Alice"
      assert person.last_name == "Aliceblat"
      assert person.tid == "alice"
      assert person.fingerprint == "2000-01-01 alice aliceblat"

      assert %{"fingerprint" => "2000-01-01 alice aliceblat"} = Version.latest_version(person).item_changes
    end

    test "create_person creates a person" do
      {:ok, person} = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person()
      assert person.fingerprint == "2000-01-01 alice aliceblat"
      assert %{"fingerprint" => "2000-01-01 alice aliceblat"} = Version.latest_version(person).item_changes
    end

    test "get_person" do
      person = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person!()
      fetched = Cases.get_person(person.id)
      assert fetched.tid == "alice"
    end

    test "list_people sorts by last name (then first name, then dob descending)" do
      Test.Fixtures.person_attrs("middle", "06-01-2000", first_name: "Alice", last_name: "Ant") |> Cases.create_person!()
      Test.Fixtures.person_attrs("last", "06-01-2000", first_name: "Billy", last_name: "Ant") |> Cases.create_person!()
      Test.Fixtures.person_attrs("first", "06-02-2000", first_name: "Alice", last_name: "Ant") |> Cases.create_person!()

      Cases.list_people() |> tids() |> assert_eq(~w{first middle last})
    end

    test "list_people can be filtered by call-list (recent positive lab results)" do
      Test.Fixtures.person_attrs("no-results", "06-01-2000") |> Cases.create_person!()

      Test.Fixtures.person_attrs("old-positive-result", "06-01-2000")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs("old-positive-result", Extra.Date.days_ago(20), result: "positive")
      |> Cases.create_lab_result!()

      Test.Fixtures.person_attrs("recent-negative-result", "06-01-2000")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs("recent-negative-result", Extra.Date.days_ago(1), result: "negative")
      |> Cases.create_lab_result!()

      Test.Fixtures.person_attrs("recent-positive-result", "06-01-2000")
      |> Cases.create_person!()
      |> Test.Fixtures.lab_result_attrs("recent-positive-result", Extra.Date.days_ago(1), result: "positive")
      |> Cases.create_lab_result!()

      Cases.list_people(:call_list) |> tids() |> assert_eq(~w{recent-positive-result})
    end

    test "update_person updates a person and saves the old version" do
      person = Test.Fixtures.person_attrs("versioned", "01-01-2000", first_name: "version-1") |> Cases.create_person!()
      {:ok, updated_person} = person |> Cases.update_person(%{first_name: "version-2"})

      assert updated_person.first_name == "version-2"

      assert Version.latest_version(updated_person).item_changes == %{
               "fingerprint" => "2000-01-01 version-2 versionedblat",
               "first_name" => "version-2"
             }

      {:ok, updated_person} = person |> Cases.update_person(%{first_name: "version-3"})

      assert Version.all_versions(updated_person) |> Euclid.Extra.Enum.pluck(:item_changes) == [
               %{"fingerprint" => "2000-01-01 version-3 versionedblat", "first_name" => "version-3"},
               %{"fingerprint" => "2000-01-01 version-2 versionedblat", "first_name" => "version-2"},
               %{"fingerprint" => "2000-01-01 version-1 versionedblat", "first_name" => "version-1"}
             ]
    end

    test "upsert_person! creates a person if one doesn't exist (based on first name, last name, dob)" do
      person = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.upsert_person!()

      assert person.dob == ~D[2000-01-01]
      assert person.first_name == "Alice"
      assert person.last_name == "Aliceblat"
      assert person.tid == "alice"
    end

    test "upsert_person! updates a person if one already exists (based on first name, last name, dob)" do
      Test.Fixtures.person_attrs("alice", "01-01-2000", tid: "first-insert") |> Cases.upsert_person!()
      Test.Fixtures.person_attrs("alice", "01-01-2000", tid: "second-insert") |> Cases.upsert_person!()

      assert [person] = Cases.list_people()

      assert person.dob == ~D[2000-01-01]
      assert person.first_name == "Alice"
      assert person.last_name == "Aliceblat"
      assert person.tid == "second-insert"
    end
  end
end
