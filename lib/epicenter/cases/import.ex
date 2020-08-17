defmodule Epicenter.Cases.Import do
  alias Epicenter.Cases
  alias Epicenter.Csv
  alias Epicenter.DateParser

  @lab_result_fields ~w{result result_date sample_date}
  @person_fields ~w{dob first_name last_name}

  def from_csv(csv_string) do
    result =
      for row <- Csv.read(csv_string), reduce: %{people: 0, lab_results: 0} do
        %{people: people, lab_results: lab_results} ->
          row
          |> Map.take(@lab_result_fields)
          |> Map.update!("sample_date", &DateParser.parse_mm_dd_yyyy!/1)
          |> Cases.create_lab_result!()

          row
          |> Map.take(@person_fields)
          |> Map.update!("dob", &DateParser.parse_mm_dd_yyyy!/1)
          |> Cases.create_person!()

          %{people: people + 1, lab_results: lab_results + 1}
      end

    {:ok, result}
  end
end
