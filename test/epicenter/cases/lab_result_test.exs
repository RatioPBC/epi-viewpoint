defmodule Epicenter.Cases.LabResultTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.LabResult
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        LabResult,
        [
          {:analyzed_on, :date},
          {:id, :id},
          {:inserted_at, :naive_datetime},
          {:person_id, :id},
          {:reported_on, :date},
          {:request_accession_number, :string},
          {:request_facility_code, :string},
          {:request_facility_name, :string},
          {:result, :string},
          {:sampled_on, :date},
          {:seq, :integer},
          {:test_type, :string},
          {:tid, :string},
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      default_attrs = Test.Fixtures.lab_result_attrs(person, "result1", "06-01-2020")
      Cases.change_lab_result(%LabResult{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "person_id is required", do: assert_invalid(new_changeset(person_id: nil))
    test "result is required", do: assert_invalid(new_changeset(result: nil))
    test "sample date is required", do: assert_invalid(new_changeset(sampled_on: nil))

    test "attributes" do
      changes = new_changeset(analyzed_on: ~D[2020-09-10], reported_on: ~D[2020-09-11], test_type: "PCR").changes
      assert changes.analyzed_on == ~D[2020-09-10]
      assert changes.reported_on == ~D[2020-09-11]
      assert changes.test_type == "PCR"
    end
  end

  describe "query" do
    import Euclid.Extra.Enum, only: [tids: 1]

    test "display_order sorts by sampled_on (desc) first, then by reported_on (desc)" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

      [
        Test.Fixtures.lab_result_attrs(person, "lab4", ~D[2020-04-13], reported_on: ~D[2020-04-26]),
        Test.Fixtures.lab_result_attrs(person, "lab1", ~D[2020-04-15], reported_on: ~D[2020-04-25]),
        Test.Fixtures.lab_result_attrs(person, "lab3", ~D[2020-04-14], reported_on: ~D[2020-04-23]),
        Test.Fixtures.lab_result_attrs(person, "lab2", ~D[2020-04-14], reported_on: ~D[2020-04-24])
      ]
      |> Enum.each(&Cases.create_lab_result!/1)

      LabResult.Query.display_order() |> Repo.all() |> tids() |> assert_eq(~w{lab1 lab2 lab3 lab4})
    end
  end
end
