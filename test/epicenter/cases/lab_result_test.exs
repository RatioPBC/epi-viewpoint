defmodule Epicenter.Cases.LabResultTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.LabResult
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        LabResult,
        [
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:request_accession_number, :string},
          {:request_facility_code, :string},
          {:request_facility_name, :string},
          {:result, :string},
          {:sample_date, :date},
          {:tid, :string},
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      default_attrs = Test.Fixtures.lab_result_attrs("result1", "06-01-2020")
      Cases.change_lab_result(%LabResult{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "result is required", do: assert_invalid(new_changeset(result: nil))
    test "sample date is required", do: assert_invalid(new_changeset(sample_date: nil))
  end
end
