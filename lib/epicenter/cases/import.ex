defmodule Epicenter.Cases.Import do
  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Csv
  alias Epicenter.DateParser
  alias Epicenter.Repo

  @required_lab_result_fields ~w{result_39 resultdate_42 datecollected_36}
  @optional_lab_result_fields ~w{lab_result_tid}
  @required_person_fields ~w{dateofbirth_8 search_firstname_2 search_lastname_1}
  @optional_person_fields ~w{caseid_0 diagaddress_street1_3 diagaddress_city_4 diagaddress_state_5 diagaddress_zip_6 person_tid phonenumber_7}

  @fields [
    required: @required_lab_result_fields ++ @required_person_fields,
    optional: @optional_lab_result_fields ++ @optional_person_fields
  ]

  defmodule ImportInfo do
    defstruct ~w{imported_person_count imported_lab_result_count total_person_count total_lab_result_count}a
  end

  def import_csv(file, %Accounts.User{} = originator) do
    Repo.transaction(fn -> import_csv_catching_exceptions(file, originator) end)
  end

  defp import_csv_catching_exceptions(file, %Accounts.User{} = originator) do
    Cases.create_imported_file(file)
    {:ok, rows} = Csv.read(file.contents, @fields)

    result =
      for row <- rows, reduce: %{people: [], lab_results: []} do
        %{people: people, lab_results: lab_results} ->
          person =
            row
            |> Map.take(@required_person_fields ++ @optional_person_fields)
            |> Map.put("originator", originator)
            |> Euclid.Extra.Map.rename_key("search_firstname_2", "first_name")
            |> Euclid.Extra.Map.rename_key("search_lastname_1", "last_name")
            |> Euclid.Extra.Map.rename_key("dateofbirth_8", "dob")
            |> Euclid.Extra.Map.rename_key("caseid_0", "external_id")
            |> Euclid.Extra.Map.rename_key("person_tid", "tid")
            |> Map.update!("dob", &DateParser.parse_mm_dd_yyyy!/1)
            |> Cases.upsert_person!()

          if Euclid.Exists.present?(Map.get(row, "phonenumber_7")),
            do: Cases.create_phone!(%{number: Map.get(row, "phonenumber_7"), person_id: person.id})

          [street, city, state, zip] =
            address_components =
            ~w{diagaddress_street1_3 diagaddress_city_4 diagaddress_state_5 diagaddress_zip_6}
            |> Enum.map(&Map.get(row, &1))

          if Euclid.Exists.any?(address_components),
            do: Cases.create_address!(%{full_address: "#{street}, #{city}, #{state} #{zip}", person_id: person.id})

          lab_result =
            row
            |> Map.take(@required_lab_result_fields ++ @optional_lab_result_fields)
            |> Map.put("person_id", person.id)
            |> Euclid.Extra.Map.rename_key("result_39", "result")
            |> Euclid.Extra.Map.rename_key("resultdate_42", "analyzed_on")
            |> Euclid.Extra.Map.rename_key("lab_result_tid", "tid")
            |> Euclid.Extra.Map.rename_key("datecollected_36", "sampled_on")
            |> Map.update!("analyzed_on", &DateParser.parse_mm_dd_yyyy!/1)
            |> Map.update!("sampled_on", &DateParser.parse_mm_dd_yyyy!/1)
            |> Cases.create_lab_result!()

          %{people: [person.id | people], lab_results: [lab_result.id | lab_results]}
      end

    import_info = %ImportInfo{
      imported_person_count: result.people |> Enum.uniq() |> length(),
      imported_lab_result_count: result.lab_results |> Enum.uniq() |> length(),
      total_person_count: Cases.count_people(),
      total_lab_result_count: Cases.count_lab_results()
    }

    Cases.broadcast({:import, import_info})

    import_info
  rescue
    error -> Repo.rollback(error)
  end
end
