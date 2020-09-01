defmodule Epicenter.Cases.ImportTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Import
  alias Epicenter.Test

  describe "from_csv" do
    setup do
      [originator: Test.Fixtures.user_attrs("originator") |> Accounts.create_user!()]
    end

    test "creates LabResult records and Person records from csv data", %{originator: originator} do
      """
      first_name , last_name , dob        , sample_date , result_date , result   , person_tid , lab_result_tid
      Alice      , Testuser  , 01/01/1970 , 06/01/2020  , 06/03/2020  , positive , alice      , alice-result-1
      Billy      , Testuser  , 03/01/1990 , 06/06/2020  , 06/07/2020  , negative , billy      , billy-result-1
      """
      |> Import.from_csv(originator)
      |> assert_eq(
        {:ok,
         %Epicenter.Cases.Import.ImportInfo{
           imported_lab_result_count: 2,
           imported_person_count: 2,
           total_lab_result_count: 2,
           total_person_count: 2
         }}
      )

      [lab_result_1, lab_result_2] = Cases.list_lab_results()
      assert lab_result_1.tid == "alice-result-1"
      assert lab_result_1.result == "positive"

      assert lab_result_2.tid == "billy-result-1"
      assert lab_result_2.result == "negative"

      [alice, billy] = Cases.list_people()
      assert alice.tid == "alice"
      assert alice.first_name == "Alice"
      assert_versioned(alice, expected_count: 1)

      assert billy.tid == "billy"
      assert billy.first_name == "Billy"
      assert_versioned(billy, expected_count: 1)
    end

    test "if two lab results have the same first_name, last_name, and dob, they are considered the same person", %{originator: originator} do
      """
      first_name , last_name , dob        , sample_date , result_date , result   , person_tid , lab_result_tid
      Alice      , Testuser  , 01/01/1970 , 06/01/2020  , 06/02/2020  , positive , alice      , alice-result
      Billy      , Testuser  , 01/01/1990 , 07/01/2020  , 07/02/2020  , negative , billy-1    , billy-1-older-result
      Billy      , Testuser  , 01/01/1990 , 08/01/2020  , 08/02/2020  , positive , billy-1    , billy-1-newer-result
      Billy      , Testuser  , 01/01/2000 , 09/01/2020  , 09/02/2020  , positive , billy-2    , billy-2-result
      """
      |> Import.from_csv(originator)
      |> assert_eq(
        {:ok,
         %Epicenter.Cases.Import.ImportInfo{
           imported_lab_result_count: 4,
           imported_person_count: 3,
           total_lab_result_count: 4,
           total_person_count: 3
         }}
      )

      [alice, billy_2, billy_1] = Cases.list_people() |> Enum.map(&Cases.preload_lab_results/1)
      assert alice.tid == "alice"
      assert alice.lab_results |> tids() == ~w{alice-result}
      assert billy_1.lab_results |> tids() == ~w{billy-1-older-result billy-1-newer-result}
      assert billy_2.lab_results |> tids() == ~w{billy-2-result}
    end
  end
end
