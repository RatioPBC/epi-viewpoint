defmodule Epicenter.Cases.ImportTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.Import

  describe "from_csv" do
    test "creates LabResults from csv data" do
      """
      first_name , last_name , dob        , thing, sample_date , result_date , result   , glorp
      Alice      , Ant       , 01/02/1970 , graz , 06/01/2020  , 06/03/2020  , positive , 393
      Billy      , Bat       , 03/04/1990 , fnord, 06/06/2020  , 06/07/2020  , negative , sn3
      """
      |> Import.from_csv()
      |> assert_eq(:ok)

      [lab_result_1, lab_result_2] = Cases.list_lab_results()
      assert lab_result_1.result == "positive"
      assert lab_result_2.result == "negative"

      [alice, billy] = Cases.list_people()
      assert alice.first_name == "Alice"
      assert billy.first_name == "Billy"
    end
  end
end
