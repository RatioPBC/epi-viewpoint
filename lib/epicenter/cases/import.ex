defmodule Epicenter.Cases.Import do
  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Csv
  alias Epicenter.DateParser
  alias Epicenter.Extra
  alias Epicenter.Repo

  # Read fields
  @required_lab_result_csv_fields ~w{datecollected_36 result_39 resultdate_42}
  @optional_lab_result_csv_fields ~w{datereportedtolhd_44 lab_result_tid orderingfacilityname_37 testname_38}
  @required_person_csv_fields ~w{dateofbirth_8 search_firstname_2 search_lastname_1}
  @optional_person_csv_fields ~w{caseid_0 diagaddress_street1_3 diagaddress_city_4 diagaddress_state_5 diagaddress_zip_6 person_tid phonenumber_7 sex_11 ethnicity_13 occupation_18 race_12}

  # Insert fields
  @lab_result_db_fields_to_insert ~w{result sampled_on analyzed_on reported_on request_accession_number request_facility_code request_facility_name test_type tid}
  @person_db_fields_to_insert ~w{person_tid dob first_name last_name external_id preferred_language sex_at_birth sex ethnicity occupation race}
  @address_db_fields_to_insert ~w{diagaddress_street1_3 diagaddress_city_4 diagaddress_state_5 diagaddress_zip_6}

  @fields [
    required: @required_lab_result_csv_fields ++ @required_person_csv_fields,
    optional: @optional_lab_result_csv_fields ++ @optional_person_csv_fields
  ]

  # Mapping from csv column name to internal db column names
  @key_map %{
    "caseid_0" => "external_id",
    "datecollected_36" => "sampled_on",
    "dateofbirth_8" => "dob",
    "datereportedtolhd_44" => "reported_on",
    "ethnicity_13" => "ethnicity",
    "lab_result_tid" => "tid",
    "occupation_18" => "occupation",
    "orderingfacilityname_37" => "request_facility_name",
    "race_12" => "race",
    "result_39" => "result",
    "resultdate_42" => "analyzed_on",
    "search_firstname_2" => "first_name",
    "search_lastname_1" => "last_name",
    "sex_11" => "sex_at_birth",
    "testname_38" => "test_type"
  }

  @date_fields ~w{dob sampled_on reported_on analyzed_on}

  defmodule ImportInfo do
    defstruct ~w{imported_people imported_person_count imported_lab_result_count total_person_count total_lab_result_count}a
  end

  def import_csv(file, %Accounts.User{} = originator) do
    Repo.transaction(fn ->
      try do
        Cases.create_imported_file(file)

        case Csv.read(file.contents, @fields) do
          {:ok, rows} ->
            rows
            |> rename_rows()
            |> transform_dates()
            |> import_rows(originator)

          {:error, message} ->
            Repo.rollback(message)
        end
      rescue
        error in NimbleCSV.ParseError ->
          Repo.rollback(error.message)

        error in Ecto.InvalidChangesetError ->
          Repo.rollback(error)
      end
    end)
  end

  defp rename_rows(rows) do
    Enum.map(rows, &Euclid.Extra.Map.rename_keys(&1, @key_map))
  end

  defp transform_dates(rows) do
    date_parser = &DateParser.parse_mm_dd_yyyy!/1
    Enum.map(rows, &Euclid.Extra.Map.transform(&1, @date_fields, date_parser))
  end

  defp import_rows(rows, originator) do
    result =
      for row <- rows, reduce: %{people: MapSet.new(), lab_results: MapSet.new()} do
        %{people: people, lab_results: lab_results} ->
          %{person: person, lab_result: lab_result} = import_row(row, originator)
          %{people: MapSet.put(people, person.id), lab_results: MapSet.put(lab_results, lab_result.id)}
      end

    import_info = %ImportInfo{
      imported_people: result.people |> MapSet.to_list() |> Cases.get_people(),
      imported_person_count: MapSet.size(result.people),
      imported_lab_result_count: MapSet.size(result.lab_results),
      total_person_count: Cases.count_people(),
      total_lab_result_count: Cases.count_lab_results()
    }

    import_info
  end

  defp import_row(row, originator) do
    person = import_person(row, originator)
    lab_result = import_lab_result(row, person)
    import_phone_number(row, person, originator)
    import_address(row, person, originator)
    %{person: person, lab_result: lab_result}
  end

  defp import_person(row, originator) do
    row
    |> Map.take(@person_db_fields_to_insert)
    |> Euclid.Extra.Map.rename_key("person_tid", "tid")
    |> in_audit_tuple(originator)
    |> Cases.upsert_person!()
  end

  defp in_audit_tuple(data, author) do
    Extra.Tuple.append(data, %AuditLog.Meta{
      author_id: author.id,
      reason_action: AuditLog.Revision.import_person_action(),
      reason_event: AuditLog.Revision.import_csv_event()
    })
  end

  defp import_lab_result(row, person) do
    row
    |> Map.take(@lab_result_db_fields_to_insert)
    |> Map.put("person_id", person.id)
    |> Cases.upsert_lab_result!()
  end

  defp import_phone_number(row, person, author) do
    if Euclid.Exists.present?(Map.get(row, "phonenumber_7")) do
      Cases.upsert_phone!(%{number: Map.get(row, "phonenumber_7"), person_id: person.id} |> in_audit_tuple(author))
    end
  end

  defp import_address(row, person, author) do
    [street, city, state, zip] = address_components = @address_db_fields_to_insert |> Enum.map(&Map.get(row, &1))

    if Euclid.Exists.any?(address_components) do
      Cases.upsert_address!(%{full_address: "#{street}, #{city}, #{state} #{zip}", person_id: person.id} |> in_audit_tuple(author))
    end
  end
end
