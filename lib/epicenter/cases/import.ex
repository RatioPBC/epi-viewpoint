defmodule Epicenter.Cases.Import do
  alias Epicenter.Cases
  alias Epicenter.Csv
  alias Epicenter.DateParser

  @lab_result_fields ~w{result result_date sample_date}
  @person_fields ~w{dob first_name last_name}

  @fields [required: @lab_result_fields ++ @person_fields, optional: ~w{}]

  def from_csv(csv_string) do
    result =
      for row <- Csv.read(csv_string, @fields), reduce: %{people: [], lab_results: []} do
        %{people: people, lab_results: lab_results} ->
          person =
            row
            |> Map.take(@person_fields)
            |> Map.update!("dob", &DateParser.parse_mm_dd_yyyy!/1)
            |> Cases.upsert_person!()

          lab_result =
            row
            |> Map.take(@lab_result_fields)
            |> Map.update!("sample_date", &DateParser.parse_mm_dd_yyyy!/1)
            |> Map.put("person_id", person.id)
            |> Cases.create_lab_result!()

          %{people: [person.id | people], lab_results: [lab_result.id | lab_results]}
      end

    {:ok, %{people: result.people |> Enum.uniq() |> length(), lab_results: result.lab_results |> Enum.uniq() |> length()}}
  end
end
