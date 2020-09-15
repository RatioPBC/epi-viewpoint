defmodule Epicenter.Test.Fixtures do
  alias Epicenter.Cases.Person
  alias Epicenter.DateParser

  def lab_result_attrs(%Person{id: person_id}, tid, sampled_on, attrs \\ %{}) do
    %{
      person_id: person_id,
      request_accession_number: "accession-" <> tid,
      request_facility_code: "facility-" <> tid,
      request_facility_name: tid <> " Lab, Inc.",
      result: "positive",
      sampled_on: sampled_on |> DateParser.parse_mm_dd_yyyy!(),
      tid: tid
    }
    |> merge_attrs(attrs)
  end

  def person_attrs(originator, tid, attrs \\ %{}) do
    %{
      dob: ~D[2000-01-01],
      first_name: String.capitalize(tid),
      last_name: "Testuser",
      originator: originator,
      preferred_language: "English",
      tid: tid
    }
    |> merge_attrs(attrs)
  end

  def address_attrs(%Person{id: person_id}, tid, street_number, attrs \\ %{}) when is_binary(tid) and is_integer(street_number) do
    %{
      full_address: "#{street_number} Test St, City, TS 00000",
      type: "home",
      person_id: person_id,
      tid: tid
    }
    |> merge_attrs(attrs)
  end

  def phone_attrs(%Person{id: person_id}, tid, attrs \\ %{}) do
    %{
      number: 1_111_111_000,
      person_id: person_id,
      type: "home",
      tid: tid
    }
    |> merge_attrs(attrs)
  end

  def email_attrs(%Person{id: person_id}, tid, attrs \\ %{}) do
    %{
      address: "#{tid}@example.com",
      person_id: person_id,
      tid: tid
    }
    |> merge_attrs(attrs)
  end

  def user_attrs(tid, attrs \\ %{}) do
    %{tid: tid, username: tid}
    |> merge_attrs(attrs)
  end

  def imported_file_attrs(tid, attrs \\ %{}) do
    %{
      file_name: "test_results_september_14_2020",
      tid: tid
    }
    |> merge_attrs(attrs)
  end

  defp merge_attrs(defaults, attrs) do
    Map.merge(defaults, Enum.into(attrs, %{}))
  end
end
