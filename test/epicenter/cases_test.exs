defmodule Epicenter.CasesTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Cases
  alias Epicenter.Test

  describe "create_lab_result!" do
    test "creates a lab result" do
      lab_result = Test.Fixtures.lab_result_attrs("result1", "06-01-2020") |> Cases.create_lab_result!()

      assert lab_result.request_accession_number == "accession-result1"
      assert lab_result.request_facility_code == "facility-result1"
      assert lab_result.request_facility_name == "result1 Lab, Inc."
      assert lab_result.result == "positive"
      assert lab_result.sample_date == ~D[2020-06-01]
      assert lab_result.tid == "result1"
    end
  end

  describe "list_lab_results" do
    test "lists all lab results, ordered by sample date" do
      Test.Fixtures.lab_result_attrs("newer", "06-03-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs("older", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs("middle", "06-02-2020") |> Cases.create_lab_result!()

      Cases.list_lab_results() |> tids() |> assert_eq(~w{older middle newer})
    end
  end
end
