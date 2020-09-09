defmodule Epicenter.Test.Fixtures do
  alias Epicenter.Cases.Person
  alias Epicenter.DateParser

  def lab_result_attrs(%Person{id: person_id}, tid, sample_date, attrs \\ %{}) do
    %{
      person_id: person_id,
      request_accession_number: "accession-" <> tid,
      request_facility_code: "facility-" <> tid,
      request_facility_name: tid <> " Lab, Inc.",
      result: "positive",
      sample_date: sample_date |> DateParser.parse_mm_dd_yyyy!(),
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

  def address_attrs(%Person{id: person_id}, tid, attrs \\ %{}) do
    %{
      full_address: "123 #{tid} st, TestAddress",
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

  defp merge_attrs(defaults, attrs) do
    Map.merge(defaults, Enum.into(attrs, %{}))
  end
end
