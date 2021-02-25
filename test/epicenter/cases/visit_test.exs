defmodule Epicenter.Cases.VisitTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Place
  alias Epicenter.Cases.Visit
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Cases.Visit,
        [
          {:id, :binary_id},
          {:deleted_at, :utc_datetime},
          {:case_investigation_id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:place_id, :binary_id},
          {:relationship, :string},
          {:seq, :integer},
          {:tid, :string},
          {:updated_at, :utc_datetime},
          {:occurred_on, :date}
        ]
      )
    end
  end

  setup :persist_admin
  @admin Test.Fixtures.admin()
  describe "changeset" do
    setup do
      place = Test.Fixtures.place_attrs(@admin, "place") |> Cases.create_place!()

      person = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, @admin, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "investigation", %{})
        |> Cases.create_case_investigation!()

      [place: place, case_investigation: case_investigation]
    end

    defp new_changeset(place, case_investigation, attr_updates \\ %{}) do
      {default_attrs, _audit_meta} = Test.Fixtures.visit_attrs(@admin, "visit", place, case_investigation)
      Visit.changeset(%Visit{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "attributes", %{place: place, case_investigation: case_investigation} do
      changes = new_changeset(place, case_investigation, %{relationship: "employee", occurred_on: ~D[2021-02-22]}).changes
      assert changes.place_id == place.id
      assert changes.case_investigation_id == case_investigation.id
      assert changes.relationship == "employee"
      assert changes.occurred_on == ~D[2021-02-22]
    end

    test "default test attrs are valid", %{place: place, case_investigation: case_investigation} do
      assert_valid(new_changeset(place, case_investigation))
    end

    test "place and case investigation are required" do
      assert_invalid(new_changeset(%Place{id: nil}, %CaseInvestigation{id: nil}))
    end
  end
end
