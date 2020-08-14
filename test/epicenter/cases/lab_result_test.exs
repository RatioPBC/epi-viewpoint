defmodule Epicenter.Cases.LabResultTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases.LabResult

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
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end
end
