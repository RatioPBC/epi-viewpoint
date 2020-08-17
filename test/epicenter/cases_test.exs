defmodule Epicenter.CasesTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Cases
  alias Epicenter.Test

  describe "importing" do
    test "import imports lab results and people" do
      """
      first_name , last_name , dob        , sample_date , result_date , result
      Alice      , Ant       , 01/02/1970 , 06/01/2020  , 06/03/2020  , positive
      Billy      , Bat       , 03/04/1990 , 06/06/2020  , 06/07/2020  , negative
      """
      |> Cases.import()
      |> assert_eq({:ok, %{people: 2, lab_results: 2}})

      Cases.list_people() |> Enum.map(& &1.first_name) |> assert_eq(["Alice", "Billy"], ignore_order: true)
      Cases.list_lab_results() |> Enum.map(& &1.result) |> assert_eq(["positive", "negative"], ignore_order: true)
    end
  end

  describe "lab results" do
    test "create_lab_result! creates a lab result" do
      lab_result = Test.Fixtures.lab_result_attrs("result1", "06-01-2020") |> Cases.create_lab_result!()

      assert lab_result.request_accession_number == "accession-result1"
      assert lab_result.request_facility_code == "facility-result1"
      assert lab_result.request_facility_name == "result1 Lab, Inc."
      assert lab_result.result == "positive"
      assert lab_result.sample_date == ~D[2020-06-01]
      assert lab_result.tid == "result1"
    end

    test "list_lab_results sorts by sample date" do
      Test.Fixtures.lab_result_attrs("newer", "06-03-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs("older", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs("middle", "06-02-2020") |> Cases.create_lab_result!()

      Cases.list_lab_results() |> tids() |> assert_eq(~w{older middle newer})
    end
  end

  describe "people" do
    test "create_person! creates a person" do
      person = Test.Fixtures.person_attrs("alice", "06-01-2020") |> Cases.create_person!()

      assert person.dob == ~D[2020-06-01]
      assert person.first_name == "Alice"
      assert person.last_name == "Aliceblat"
      assert person.tid == "alice"
    end

    test "list_people sorts by last name (then first name, then dob descending)" do
      Test.Fixtures.person_attrs("middle", "06-01-2020", first_name: "Alice", last_name: "Ant") |> Cases.create_person!()
      Test.Fixtures.person_attrs("last", "06-01-2020", first_name: "Billy", last_name: "Ant") |> Cases.create_person!()
      Test.Fixtures.person_attrs("first", "06-02-2020", first_name: "Alice", last_name: "Ant") |> Cases.create_person!()

      Cases.list_people() |> tids() |> assert_eq(~w{first middle last})
    end
  end
end
