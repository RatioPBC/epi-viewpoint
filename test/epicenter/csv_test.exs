defmodule Epicenter.CsvTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Csv

  describe "import" do
    test "reads a csv file" do
      """
      first_name , last_name , dob        , thing, sample_date , result_date , result   , glorp
      Alice      , Ant       , 01/02/1970 , graz , 06/01/2020  , 06/03/2020  , positive , 393
      Billy      , Bat       , 03/04/1990 , fnord, 06/06/2020  , 06/07/2020  , negative , sn3
      """
      |> Csv.import()
      |> assert_eq([
        %{
          "first_name" => "Alice",
          "last_name" => "Ant",
          "dob" => "01/02/1970",
          "sample_date" => "06/01/2020",
          "result_date" => "06/03/2020",
          "result" => "positive"
        },
        %{
          "first_name" => "Billy",
          "last_name" => "Bat",
          "dob" => "03/04/1990",
          "sample_date" => "06/06/2020",
          "result_date" => "06/07/2020",
          "result" => "negative"
        }
      ])
    end
  end
end
