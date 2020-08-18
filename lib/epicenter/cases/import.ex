defmodule Epicenter.Cases.Import do
  alias Epicenter.Cases
  alias Epicenter.Csv
  alias Epicenter.DateParser

  @required_lab_result_fields ~w{result result_date sample_date}
  @optional_lab_result_fields ~w{lab_result_tid}
  @required_person_fields ~w{dob first_name last_name}
  @optional_person_fields ~w{person_tid}

  @fields [
    required: @required_lab_result_fields ++ @required_person_fields,
    optional: @optional_lab_result_fields ++ @optional_person_fields
  ]

  def from_csv(csv_string) do
    {:ok, rows} = Csv.read(csv_string, @fields)

    result =
      for row <- rows, reduce: %{people: [], lab_results: []} do
        %{people: people, lab_results: lab_results} ->
          person =
            row
            |> Map.take(@required_person_fields ++ @optional_person_fields)
            |> Map.update!("dob", &DateParser.parse_mm_dd_yyyy!/1)
            |> Euclid.Extra.Map.rename_key("person_tid", "tid")
            |> Cases.upsert_person!()

          lab_result =
            row
            |> Map.take(@required_lab_result_fields ++ @optional_lab_result_fields)
            |> Map.update!("sample_date", &DateParser.parse_mm_dd_yyyy!/1)
            |> Map.put("person_id", person.id)
            |> Euclid.Extra.Map.rename_key("lab_result_tid", "tid")
            |> Cases.create_lab_result!()

          %{people: [person.id | people], lab_results: [lab_result.id | lab_results]}
      end

    {:ok, %{people: result.people |> Enum.uniq() |> length(), lab_results: result.lab_results |> Enum.uniq() |> length()}}
  end
end
