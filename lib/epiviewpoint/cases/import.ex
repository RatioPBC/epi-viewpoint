defmodule EpiViewpoint.Cases.Import do
  alias EpiViewpoint.Accounts
  alias EpiViewpoint.AuditLog
  alias EpiViewpoint.BulkFhirParser
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Import
  alias EpiViewpoint.Cases.LabResult
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.DataFile
  alias EpiViewpoint.DateParser
  alias EpiViewpoint.Extra
  alias EpiViewpoint.Repo

  # Read fields
  @required_lab_result_data_fields ~w{sampled_on result analyzed_on}
  @optional_lab_result_data_fields ~w{reported_on tid request_facility_name test_type}
  @required_person_data_fields ~w{dob first_name last_name}
  @optional_person_data_fields ~w{external_id diagaddress_street1 diagaddress_city diagaddress_state diagaddress_zip person_tid phonenumber sex_at_birth ethnicity occupation race}

  # Insert fields
  @lab_result_db_fields_to_insert ~w{result sampled_on analyzed_on reported_on request_accession_number request_facility_code request_facility_name test_type tid}
  @person_db_fields_to_insert ~w{person_tid dob first_name last_name external_id preferred_language sex_at_birth ethnicity occupation race}
  @address_db_fields_to_insert ~w{diagaddress_street1 diagaddress_city diagaddress_state diagaddress_zip}

  @fields [
    required: @required_lab_result_data_fields ++ @required_person_data_fields,
    optional: @optional_lab_result_data_fields ++ @optional_person_data_fields
  ]

  # Mapping from data column name to internal db column names
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
    defstruct [
      :imported_people,
      :imported_person_count,
      :imported_lab_result_count,
      :skipped_row_count,
      :total_person_count,
      :total_lab_result_count,
      skipped_row_error_messages: []
    ]
  end

  def import_bulk_fhir_data_file(lab_result_data_file_list, originator) do
    {:ok, bulk_fhir_data} = BulkFhirParser.parse_bulk_fhir(lab_result_data_file_list)
    import_data_file(bulk_fhir_data, originator)
  end

  def import_data_file(_file, %{admin: false}), do: {:error, "Originator must be an admin"}

  def import_data_file(file, %Accounts.User{} = originator) do
    Repo.transaction(fn ->
      try do
        Cases.create_imported_file(in_audit_tuple(file, originator, AuditLog.Revision.import_file_action()))

        with {:ok, rows} <- file_router(file),
             {:transform_dates, {:ok, rows}} <- {:transform_dates, transform_dates(rows)},
             rows = {rows, []} do
          case import_rows(rows, originator) do
            {:ok, import_info} -> import_info
            {:error, other} -> Repo.rollback(other)
          end
        else
          {:error, :missing_headers, headers} ->
            inverse_key_map = @key_map |> Enum.map(fn {k, v} -> {v, k} end) |> Map.new()

            headers_string =
              headers
              |> Enum.map(&Map.get(inverse_key_map, &1, &1))
              |> Enum.sort()
              |> Enum.map(&Extra.String.add_placeholder_suffix/1)
              |> Enum.join(", ")

            Repo.rollback(user_readable: "Missing required fields: #{headers_string}")

          {:invalid_csv, message} ->
            Repo.rollback(user_readable: "Invalid CSV: \n #{message}")

          {:transform_dates, {:error, message}} ->
            Repo.rollback(message)
        end
      rescue
        error in Ecto.InvalidChangesetError ->
          Repo.rollback(error)
      end
    end)
  end

  defp file_router(file) do
    case Path.extname(file.file_name) do
      ".csv" -> DataFile.read(file.contents, :csv, &rename_headers/1, @fields)
      ".ndjson" -> DataFile.read(file.contents, :ndjson, &rename_headers/1, @fields)
      ".bulk_fhir" -> DataFile.read(file.list, :bulk_fhir, &rename_headers/1, @fields)
      _ -> {:error, "Unsupported file type: #{file.extension}"}
    end
  end

  def reject_rows_with_blank_key_values(rows, key) do
    error_message = "Missing required field: #{key}"

    {importable_rows, error_messages} =
      rows
      |> Enum.reduce({[], []}, fn row, {importable_rows, error_messages} ->
        cond do
          !is_map_key(row, key) -> {[row | importable_rows], error_messages}
          row |> Map.get(key) |> Euclid.Exists.blank?() -> {importable_rows, [error_message | error_messages]}
          true -> {[row | importable_rows], error_messages}
        end
      end)

    {Enum.reverse(importable_rows), error_messages}
  end

  # # #

  defp rename_headers(headers) do
    headers
    |> Enum.map(&Extra.String.remove_numeric_suffix/1)
    |> Enum.map(fn h -> Map.get(@key_map, h, h) end)
  end

  defp transform_dates(rows) do
    Enum.reduce(rows, {:ok, []}, fn
      row, {:ok, rows} ->
        case transform_dates_row(row) do
          {:ok, row} -> {:ok, rows ++ [row]}
          other -> other
        end

      _, other ->
        other
    end)
  end

  defp transform_dates_row(row) do
    date_parser = &DateParser.parse_mm_dd_yyyy/1

    Enum.reduce(@date_fields, {:ok, row}, fn
      date_field, {:ok, row} ->
        case date_parser.(Map.get(row, date_field)) do
          {:ok, date} -> {:ok, Map.put(row, date_field, date)}
          other -> other
        end

      _, other ->
        other
    end)
  end

  defp import_rows({importable_rows, error_messages}, originator) do
    result =
      for row <- importable_rows, reduce: %{people: MapSet.new(), lab_results: MapSet.new()} do
        %{people: people, lab_results: lab_results} ->
          case import_row(row, originator) do
            %{person: person, lab_result: lab_result} ->
              %{people: MapSet.put(people, person.id), lab_results: MapSet.put(lab_results, lab_result.id)}

            other ->
              other
          end

        other ->
          other
      end

    with %{people: people, lab_results: lab_results} <- result do
      {:ok,
       %ImportInfo{
         imported_people: people |> MapSet.to_list() |> Cases.get_people(originator),
         imported_person_count: MapSet.size(result.people),
         imported_lab_result_count: MapSet.size(lab_results),
         skipped_row_count: length(error_messages),
         skipped_row_error_messages: error_messages,
         total_person_count: Cases.count_people(),
         total_lab_result_count: Cases.count_lab_results()
       }}
    end
  end

  defp import_row(row, originator) do
    person = Cases.find_matching_person(row) |> Cases.preload_demographics()

    with {:ok, person} <- import_person(person, row, originator),
         {:ok, _} <- import_demographic(person, row, originator) do
      %LabResult{} = lab_result = import_lab_result(row, person, originator)
      find_or_create_case_investigation_for_positive_lab_result(lab_result, person, originator)
      import_phone_number(row, person, originator)
      import_address(row, person, originator)
      person = person |> unarchive_person_for_positive_lab_result(lab_result, originator)
      %{person: person, lab_result: lab_result}
    end
  end

  defp unarchive_person_for_positive_lab_result(
         person,
         %LabResult{is_positive_or_detected: is_positive_or_detected} = _lab_result,
         originator
       ) do
    cond do
      is_positive_or_detected -> unarchive_person(person, originator)
      true -> person
    end
  end

  defp unarchive_person(person, originator) do
    {:ok, person} =
      person.id
      |> Cases.unarchive_person(
        originator,
        audit_tuple(originator, AuditLog.Revision.archive_person_action())
      )

    person
  end

  def find_or_create_case_investigation_for_positive_lab_result(
        %LabResult{is_positive_or_detected: is_positive_or_detected} = lab_result,
        person,
        originator
      ) do
    cond do
      is_positive_or_detected -> find_or_create_case_investigation(lab_result, person, originator)
      true -> :not_positive
    end
  end

  defp find_or_create_case_investigation(%LabResult{id: lab_result_id}, %Person{id: person_id} = person, originator) do
    person
    |> Cases.preload_case_investigations()
    |> Map.get(:case_investigations)
    |> case do
      [] ->
        # TODO currently assuming max of 1 case investigation and so, hardcoding name to "001"
        %{person_id: person_id, initiating_lab_result_id: lab_result_id, name: "001"}
        |> in_audit_tuple(originator, AuditLog.Revision.insert_case_investigation_action())
        |> Cases.create_case_investigation!()

        :ok

      [_case_investigation | _tl] ->
        :already_exists
    end
  end

  defp import_demographic(person, row, originator) do
    row
    |> Map.take(@person_db_fields_to_insert)
    |> Euclid.Extra.Map.rename_key("person_tid", "tid")
    |> Import.Ethnicity.build_attrs()
    |> Map.update("race", nil, &Cases.Demographic.build_attrs(&1, :race))
    |> Map.put("person_id", person.id)
    |> Map.put("source", "import")
    |> in_audit_tuple(originator, AuditLog.Revision.insert_demographics_action())
    |> Cases.create_demographic()
  end

  defp import_person(person, row, originator) do
    attrs =
      row
      |> Map.take(@person_db_fields_to_insert)
      |> Euclid.Extra.Map.rename_key("person_tid", "tid")
      |> Import.Ethnicity.build_attrs()
      |> Map.update("race", nil, &Cases.Demographic.build_attrs(&1, :race))
      |> strip_updates_to_existing_data(person)
      |> in_audit_tuple(originator, AuditLog.Revision.upsert_person_action())

    if person do
      Cases.update_person(person, attrs)
    else
      Cases.create_person(attrs)
    end
  end

  defp strip_updates_to_existing_data(row, nil), do: row

  defp strip_updates_to_existing_data(row, person) do
    keys =
      Enum.reduce(row, [], fn {key, _value}, update_keys ->
        if Extra.Map.has_key?(person, key, :coerce_key_to_existing_atom),
          do: update_keys,
          else: [key | update_keys]
      end)

    Map.take(row, keys)
  end

  defp import_lab_result(row, person, author) do
    row
    |> Map.take(@lab_result_db_fields_to_insert)
    |> Map.put("person_id", person.id)
    |> Map.put("source", "import")
    |> in_audit_tuple(author, AuditLog.Revision.upsert_lab_result_action())
    |> Cases.upsert_lab_result!()
  end

  defp import_phone_number(row, person, author) do
    if Euclid.Exists.present?(Map.get(row, "phonenumber")) do
      Cases.upsert_phone!(
        %{number: Map.get(row, "phonenumber"), person_id: person.id, source: "import"}
        |> in_audit_tuple(author, AuditLog.Revision.upsert_phone_number_action())
      )
    end
  end

  defp import_address(row, person, author) do
    [street, city, state, zip] = address_components = @address_db_fields_to_insert |> Enum.map(&Map.get(row, &1))

    if Euclid.Exists.any?(address_components) do
      Cases.upsert_address!(
        %{street: street, city: city, state: state, postal_code: zip, person_id: person.id, source: "import"}
        |> in_audit_tuple(author, AuditLog.Revision.upsert_address_action())
      )
    end
  end

  defp audit_tuple(originator, reason_action) do
    %AuditLog.Meta{
      author_id: originator.id,
      reason_action: reason_action,
      reason_event: AuditLog.Revision.import_file_event()
    }
  end

  defp in_audit_tuple(data, author, reason_action) do
    {data,
     %AuditLog.Meta{
       author_id: author.id,
       reason_action: reason_action,
       reason_event: AuditLog.Revision.import_file_event()
     }}
  end
end
