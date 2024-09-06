defmodule EpiViewpoint.BulkFhirParser do
  def parse_bulk_fhir(file_list) do
    file_list
    |> load_resources()
    |> extract_resources()
    |> join_resources()
    |> to_map()
  end

  def load_resources(file_list) do
    file_list
    |> Enum.reduce(%{}, fn file, acc ->
      resources = load_resource_file(file.contents)

      Enum.reduce(resources, acc, fn resource, inner_acc ->
        type = resource.resource_type
        Map.update(inner_acc, type, [resource], &[resource | &1])
      end)
    end)
  end

  def load_resource_file(file_content) do
    file_content
    |> String.split("\n")
    |> Stream.map(&String.trim/1)
    |> Stream.map(&json_to_kindle_schema(&1, "EpiViewpoint.R4"))
    |> Enum.to_list()
  end

  def extract_resources(resources) do
    resources
    |> Enum.reduce(%{}, fn {resource_type, resource_list}, acc ->
      Map.put(acc, resource_type, extract_resource(resource_type, resource_list))
    end)
  end

  def extract_resource("Patient", resource_list) do
    resource_list
    |> Enum.map(fn
      %Epiviewpoint.R4.Patient{
        id: caseid,
        identifier: [%Epiviewpoint.R4.Identifier{value: person_tid}],
        name: [%Epiviewpoint.R4.HumanName{given: [search_firstname], family: search_lastname}],
        birth_date: dateofbirth,
        gender: sex,
        address: [
          %Epiviewpoint.R4.Address{
            line: [diagaddress_street1],
            city: diagaddress_city,
            state: diagaddress_state,
            postal_code: diagaddress_zip
          }
        ],
        telecom: [%Epiviewpoint.R4.ContactPoint{value: phonenumber}],
        extension: extensions
      } = _resource ->
        %{
          caseid: caseid,
          person_tid: person_tid,
          search_firstname: search_firstname,
          search_lastname: search_lastname,
          dateofbirth: Calendar.strftime(dateofbirth, "%m/%d/%Y"),
          sex: sex |> to_string() |> String.capitalize(),
          diagaddress_street1: diagaddress_street1,
          diagaddress_city: diagaddress_city,
          diagaddress_state: diagaddress_state,
          diagaddress_zip: diagaddress_zip,
          phonenumber: phonenumber,
          ethnicity: find_extension(extensions, "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"),
          occupation: find_extension(extensions),
          race: find_extension(extensions, "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race")
        }
    end)
  end

  def extract_resource("Observation", resource_list) do
    resource_list
    |> Enum.map(fn
      %Epiviewpoint.R4.Observation{
        id: lab_result_tid,
        subject: %Epiviewpoint.R4.Reference{reference: "Patient/" <> pat_id},
        effective_date_time: datecollected,
        issued: resultdate,
        code: %Epiviewpoint.R4.CodeableConcept{text: testname},
        interpretation: [%Epiviewpoint.R4.CodeableConcept{coding: [%Epiviewpoint.R4.Coding{display: result}]}],
        performer: [%Epiviewpoint.R4.Reference{reference: "Organization/" <> org_id}],
        extension: extensions
      } = _resource ->
        %{
          lab_result_tid: lab_result_tid,
          pat_id: pat_id,
          datecollected: datecollected,
          resultdate: resultdate |> DateTime.to_date() |> Calendar.strftime("%m/%d/%Y"),
          testname: testname,
          result: result,
          org_id: org_id,
          datereportedtolhd: find_extension(extensions)
        }
    end)
  end

  def extract_resource("Organization", resource_list) do
    resource_list
    |> Enum.map(fn
      %Epiviewpoint.R4.Organization{
        id: orgnization_id,
        name: orderingfacilityname
      } = _resource ->
        %{
          orgnization_id: orgnization_id,
          orderingfacilityname: orderingfacilityname
        }
    end)
  end

  # Helper function to find extension values
  defp find_extension(extensions, url \\ nil) do
    Enum.find_value(extensions, fn
      %Epiviewpoint.R4.Extension{
        url: ^url,
        extension: [%Epiviewpoint.R4.Extension{url: "ombCategory", value_coding: %Epiviewpoint.R4.Coding{display: value}}, _]
      } ->
        value

      %Epiviewpoint.R4.Extension{url: "http://hl7.org/fhir/StructureDefinition/patient-occupation", value_string: value} ->
        value

      %Epiviewpoint.R4.Extension{url: "http://hl7.org/fhir/StructureDefinition/datereportedtolhd", value_date: value} ->
        value

      _ ->
        nil
    end)
  end

  defp json_to_kindle_schema(json, version_namespace) do
    map = Jason.decode!(json)
    Kindling.Converter.convert(version_namespace, map)
  end

  def join_resources(resources) do
    patients = Map.get(resources, "Patient", [])
    observations = Map.get(resources, "Observation", [])
    organizations = Map.get(resources, "Organization", [])

    observations
    |> Enum.map(fn observation ->
      patient = Enum.find(patients, &(&1.caseid == observation.pat_id))
      organization = Enum.find(organizations, &(&1.orgnization_id == observation.org_id))

      observation
      |> Map.merge(patient || %{})
      |> Map.merge(organization || %{})
      |> Map.drop([:pat_id, :org_id, :orgnization_id])
    end)
  end

  def to_map(resources) do
    %{file_name: "load.bulk_fhir", contents: resources}
  end
end
