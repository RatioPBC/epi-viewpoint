defmodule Epicenter.Cases.Import do
  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Csv
  alias Epicenter.DateParser
  alias Epicenter.Extra
  alias Epicenter.Repo

  # Read fields
  @required_lab_result_csv_fields ~w{sampled_on result analyzed_on}
  @optional_lab_result_csv_fields ~w{reported_on tid request_facility_name test_type}
  @required_person_csv_fields ~w{dob first_name last_name}
  @optional_person_csv_fields ~w{external_id diagaddress_street1 diagaddress_city diagaddress_state diagaddress_zip person_tid phonenumber sex_at_birth ethnicity occupation race}

  # Insert fields
  @lab_result_db_fields_to_insert ~w{result sampled_on analyzed_on reported_on request_accession_number request_facility_code request_facility_name test_type tid}
  @person_db_fields_to_insert ~w{person_tid dob first_name last_name external_id preferred_language sex_at_birth ethnicity occupation race}
  @address_db_fields_to_insert ~w{diagaddress_street1 diagaddress_city diagaddress_state diagaddress_zip}

  @fields [
    required: @required_lab_result_csv_fields ++ @required_person_csv_fields,
    optional: @optional_lab_result_csv_fields ++ @optional_person_csv_fields
  ]

  # Mapping from csv column name to internal db column names
  @key_map %{
    "caseid" => "external_id",
    "datecollected" => "sampled_on",
    "dateofbirth" => "dob",
    "datereportedtolhd" => "reported_on",
    "ethnicity" => "ethnicity",
    "lab_result_tid" => "tid",
    "occupation" => "occupation",
    "orderingfacilityname" => "request_facility_name",
    "race" => "race",
    "result" => "result",
    "resultdate" => "analyzed_on",
    "search_firstname" => "first_name",
    "search_lastname" => "last_name",
    "sex" => "sex_at_birth",
    "testname" => "test_type"
  }

  @date_fields ~w{dob sampled_on reported_on analyzed_on}

  defmodule ImportInfo do
    defstruct ~w{imported_people imported_person_count imported_lab_result_count total_person_count total_lab_result_count}a
  end

  def import_csv(file, %Accounts.User{} = originator) do
    Repo.transaction(fn ->
      try do
        Cases.create_imported_file(in_audit_tuple(file, originator, AuditLog.Revision.import_csv_action()))

        case Csv.read(file.contents, &rename_headers/1, @fields) do
          {:ok, rows} ->
            rows
            |> transform_dates()
            |> reject_rows_with_blank_key_values("dob")
            |> import_rows(originator)

          {:error, :missing_headers, headers} ->
            inverse_key_map = @key_map |> Enum.map(fn {k, v} -> {v, k} end) |> Map.new()

            headers_string =
              headers
              |> Enum.map(&Map.get(inverse_key_map, &1, &1))
              |> Enum.sort()
              |> Enum.map(&Extra.String.add_placeholder_suffix/1)
              |> Enum.join(", ")

            Repo.rollback(user_readable: "Missing required columns: #{headers_string}")
        end
      rescue
        error in NimbleCSV.ParseError ->
          Repo.rollback(error.message)

        error in Ecto.InvalidChangesetError ->
          Repo.rollback(error)

        error in Epicenter.DateParsingError ->
          Repo.rollback(error)
      end
    end)
  end

  def reject_rows_with_blank_key_values(rows, key) do
    rows
    |> Enum.reject(fn
      row when is_map_key(row, key) -> row |> Map.get(key) |> Euclid.Exists.blank?()
      _row -> false
    end)
  end

  # # #

  defp rename_headers(headers) do
    headers
    |> Enum.map(&Extra.String.remove_numeric_suffix/1)
    |> Enum.map(fn h -> Map.get(@key_map, h, h) end)
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
    lab_result = import_lab_result(row, person, originator)
    import_phone_number(row, person, originator)
    import_address(row, person, originator)
    %{person: person, lab_result: lab_result}
  end

  defp import_person(row, originator) do
    row
    |> Map.take(@person_db_fields_to_insert)
    |> Euclid.Extra.Map.rename_key("person_tid", "tid")
    |> in_audit_tuple(originator, AuditLog.Revision.upsert_person_action())
    |> Cases.upsert_person!()
  end

  defp import_lab_result(row, person, author) do
    row
    |> Map.take(@lab_result_db_fields_to_insert)
    |> Map.put("person_id", person.id)
    |> in_audit_tuple(author, AuditLog.Revision.upsert_lab_result_action())
    |> Cases.upsert_lab_result!()
  end

  defp import_phone_number(row, person, author) do
    if Euclid.Exists.present?(Map.get(row, "phonenumber")) do
      Cases.upsert_phone!(
        %{number: Map.get(row, "phonenumber"), person_id: person.id}
        |> in_audit_tuple(author, AuditLog.Revision.upsert_phone_number_action())
      )
    end
  end

  defp import_address(row, person, author) do
    [street, city, state, zip] = address_components = @address_db_fields_to_insert |> Enum.map(&Map.get(row, &1))

    if Euclid.Exists.any?(address_components) do
      Cases.upsert_address!(
        %{full_address: "#{street}, #{city}, #{state} #{zip}", street: street, city: city, state: state, postal_code: zip, person_id: person.id}
        |> in_audit_tuple(author, AuditLog.Revision.upsert_address_action())
      )
    end
  end

  defp in_audit_tuple(data, author, reason_action) do
    Extra.Tuple.append(data, %AuditLog.Meta{
      author_id: author.id,
      reason_action: reason_action,
      reason_event: AuditLog.Revision.import_csv_event()
    })
  end
end
