defmodule Epicenter.Test.Fixtures do
  alias Epicenter.DateParser

  def lab_result_attrs(tid, sample_date, attrs \\ %{}) do
    %{
      request_accession_number: "accession-" <> tid,
      request_facility_code: "facility-" <> tid,
      request_facility_name: tid <> " Lab, Inc.",
      result: "positive",
      sample_date: sample_date |> DateParser.parse_mm_dd_yyyy!(),
      tid: tid
    }
    |> Map.merge(Enum.into(attrs, %{}))
  end
end
