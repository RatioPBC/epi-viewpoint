defmodule EpiViewpoint.BulkFhirParser do
  def parse_bulk_fhir(file_list) do
    with {:ok, contents} <- combine_contents(file_list),
         {:ok, resources} <- load_resources(file_list),
         {:ok, extracted} <- extract_resources(resources),
         {:ok, joined} <- join_resources(extracted) do
      {:ok, to_map(joined, contents)}
    end
  end

  defp combine_contents(file_list) do
    contents = file_list |> Enum.map(& &1.contents) |> List.to_string()
    {:ok, contents}
  end

  defp load_resources(file_list) do
    result = Enum.reduce_while(file_list, {:ok, %{}}, fn file, {:ok, acc} ->
      case load_resource_file(file.contents) do
        {:ok, resources} -> {:cont, {:ok, group_resources(resources, acc)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)

    case result do
      {:ok, resources} -> {:ok, resources}
      {:error, reason} -> {:error, reason}
    end
  end

  defp group_resources(resources, acc) do
    Enum.reduce(resources, acc, fn resource, acc ->
      Map.update(acc, resource.resource_type, [resource], &[resource | &1])
    end)
  end

  defp load_resource_file(file_content) do
    result = file_content
    |> String.split("\n")
    |> Stream.map(&String.trim/1)
    |> Stream.filter(&filter_empty_lines/1)
    |> Stream.map(&json_to_kindle_schema/1)
    |> Enum.to_list()

    {:ok, result}
  rescue
    e -> {:error, "Failed to load resource file: #{inspect(e)}"}
  end

  defp json_to_kindle_schema(json) do
    case Jason.decode(json) do
      {:ok, map} -> Kindling.Converter.convert("EpiViewpoint.R4", map)
      {:error, reason} -> {:error, "Failed to decode JSON: #{inspect(reason)}"}
    end
  end

  defp extract_resources(resources) do
    result = Enum.reduce_while(resources, {:ok, %{}}, fn {resource_type, resource_list}, {:ok, acc} ->
      case extract_resource(resource_type, resource_list) do
        {:ok, extracted} -> {:cont, {:ok, Map.put(acc, resource_type, extracted)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)

    case result do
      {:ok, extracted} -> {:ok, extracted}
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_resource("Patient", resource_list) do
    {:ok, Enum.map(resource_list, &extract_patient/1)}
  end

  defp extract_resource("Observation", resource_list) do
    {:ok, Enum.map(resource_list, &extract_observation/1)}
  end

  defp extract_resource("Organization", resource_list) do
    {:ok, Enum.map(resource_list, &extract_organization/1)}
  end

  defp extract_resource(unknown_type, _) do
    {:error, "Unknown resource type: #{unknown_type}"}
  end

  defp extract_patient(%EpiViewpoint.R4.Patient{
         id: caseid,
         identifier: [%EpiViewpoint.R4.Identifier{value: person_tid}],
         name: [%EpiViewpoint.R4.HumanName{given: [search_firstname], family: search_lastname}],
         birth_date: dateofbirth,
         gender: sex,
         address: [
           %EpiViewpoint.R4.Address{
             line: [diagaddress_street1],
             city: diagaddress_city,
             state: diagaddress_state,
             postal_code: diagaddress_zip
           }
         ],
         telecom: [%EpiViewpoint.R4.ContactPoint{value: phonenumber}],
         extension: extensions
       }) do
    %{
      caseid: caseid,
      person_tid: person_tid,
      search_firstname: search_firstname,
      search_lastname: search_lastname,
      dateofbirth: format_date(dateofbirth),
      sex: String.capitalize(to_string(sex)),
      diagaddress_street1: diagaddress_street1,
      diagaddress_city: diagaddress_city,
      diagaddress_state: diagaddress_state,
      diagaddress_zip: diagaddress_zip,
      phonenumber: phonenumber,
      ethnicity: find_extension(extensions, "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"),
      occupation: find_extension(extensions),
      race: find_extension(extensions, "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race")
    }
  end

  defp extract_observation(%EpiViewpoint.R4.Observation{
         id: lab_result_tid,
         subject: %EpiViewpoint.R4.Reference{reference: "Patient/" <> pat_id},
         effective_date_time: datecollected,
         issued: resultdate,
         code: %EpiViewpoint.R4.CodeableConcept{text: testname},
         interpretation: [%EpiViewpoint.R4.CodeableConcept{coding: [%EpiViewpoint.R4.Coding{display: result}]}],
         performer: [%EpiViewpoint.R4.Reference{reference: "Organization/" <> org_id}],
         extension: extensions
       }) do
    %{
      lab_result_tid: lab_result_tid,
      pat_id: pat_id,
      datecollected: datecollected,
      resultdate: format_date(resultdate),
      testname: testname,
      result: result,
      org_id: org_id,
      datereportedtolhd: find_extension(extensions)
    }
  end

  defp extract_organization(%EpiViewpoint.R4.Organization{
         id: organization_id,
         name: ordering_facility_name
       }) do
    %{
      organization_id: organization_id,
      ordering_facility_name: ordering_facility_name
    }
  end

  defp find_extension(extensions, url \\ nil) do
    Enum.find_value(extensions, fn
      %EpiViewpoint.R4.Extension{
        url: ^url,
        extension: [%EpiViewpoint.R4.Extension{url: "ombCategory", value_coding: %EpiViewpoint.R4.Coding{display: value}}, _]
      } ->
        value

      %EpiViewpoint.R4.Extension{url: "http://hl7.org/fhir/StructureDefinition/patient-occupation", value_string: value} ->
        value

      %EpiViewpoint.R4.Extension{url: "http://hl7.org/fhir/StructureDefinition/datereportedtolhd", value_date: value} ->
        value

      _ ->
        nil
    end)
  end

  defp join_resources(resources) do
    patients = Map.get(resources, "Patient", [])
    observations = Map.get(resources, "Observation", [])
    organizations = Map.get(resources, "Organization", [])

    joined = observations
    |> Enum.map(fn observation ->
      patient = Enum.find(patients, &(&1.caseid == observation.pat_id))
      organization = Enum.find(organizations, &(&1.organization_id == observation.org_id))

      observation
      |> Map.merge(patient || %{})
      |> Map.merge(organization || %{})
      |> Map.drop([:pat_id, :org_id, :organization_id])
    end)

    {:ok, joined}
  end

  defp to_map(resources, contents) do
    %{file_name: "load.bulk_fhir", contents: contents, list: resources}
  end

  defp filter_empty_lines(line) do
    line != ""
  end

  defp format_date(date) when is_struct(date, Date), do: Calendar.strftime(date, "%m/%d/%Y")
  defp format_date(datetime) when is_struct(datetime, DateTime), do: datetime |> DateTime.to_date() |> format_date()
end
