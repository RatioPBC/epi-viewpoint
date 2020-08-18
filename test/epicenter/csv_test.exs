defmodule Epicenter.CsvTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Csv

  describe "read" do
    test "reads a csv file" do
      """
      first_name , last_name , dob        , thing, sample_date , result_date , result   , glorp
      Alice      , Ant       , 01/02/1970 , graz , 06/01/2020  , 06/03/2020  , positive , 393
      Billy      , Bat       , 03/04/1990 , fnord, 06/06/2020  , 06/07/2020  , negative , sn3
      """
      |> Csv.read(required: ~w{first_name last_name dob sample_date result_date result}, optional: ~w{})
      |> assert_eq(
        {:ok,
         [
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
         ]}
      )
    end

    test "fails if required header is missing" do
      """
      column_a , column_b
      value_a  , value_b
      """
      |> Csv.read(required: ~w{column_a column_b column_c column_d}, optional: ~w{})
      |> assert_eq({:error, "Missing required columns: column_c, column_d"})
    end
  end
end
