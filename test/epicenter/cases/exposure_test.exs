defmodule Epicenter.Cases.ExposureTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Exposure
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Exposure,
        [
          {:exposed_person_id, :binary_id},
          {:exposing_case_id, :binary_id},
          {:guardian_name, :string},
          {:guardian_phone, :string},
          {:household_member, :boolean},
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:most_recent_date_together, :date},
          {:relationship_to_case, :string},
          {:seq, :integer},
          {:deleted_at, :utc_datetime},
          {:tid, :string},
          {:under_18, :boolean},
          {:updated_at, :utc_datetime}
        ]
      )
    end
  end

  defp new_changeset(attr_updates) do
    default_attrs = Test.Fixtures.exposure_attrs(%CaseInvestigation{id: "flimflams"}, "validation example")
    Exposure.changeset(%Exposure{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
  end

  test "validates guardian phone format" do
    assert_invalid(new_changeset(guardian_phone: "211-111-1000"))
    assert_valid(new_changeset(guardian_phone: "111-111-1000"))
  end

  test "validates presence of most recent date together", do: assert_invalid(new_changeset(most_recent_date_together: nil))
  test "validates presence of relationship_to_case", do: assert_invalid(new_changeset(relationship_to_case: ""))

  test "validates guardian_name if a minor" do
    assert_invalid(new_changeset(guardian_name: "", under_18: true))
    assert_valid(new_changeset(guardian_name: "", under_18: false))
  end
end
