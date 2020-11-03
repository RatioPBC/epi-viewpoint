defmodule Epicenter.Cases.CaseInvestigationTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        CaseInvestigation,
        [
          {:clinical_status, :string},
          {:discontinue_reason, :string},
          {:discontinued_at, :utc_datetime},
          {:id, :id},
          {:initiated_by_id, :id},
          {:inserted_at, :naive_datetime},
          {:name, :string},
          {:person_id, :id},
          {:person_interviewed, :string},
          {:started_at, :utc_datetime},
          {:seq, :integer},
          {:symptom_onset_date, :date},
          {:symptoms, :array},
          {:tid, :string},
          {:updated_at, :naive_datetime}
        ]
      )
    end
  end

  describe "associations" do
    test "it has a reference to the lab result that spawned it" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result1 = Test.Fixtures.lab_result_attrs(alice, user, "lab_result1", ~D[2020-10-27]) |> Cases.create_lab_result!()
      lab_result2 = Test.Fixtures.lab_result_attrs(alice, user, "lab_result2", ~D[2020-10-29]) |> Cases.create_lab_result!()
      Test.Fixtures.case_investigation_attrs(alice, lab_result1, user, "investigation1") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(alice, lab_result2, user, "investigation2") |> Cases.create_case_investigation!()

      alice
      |> Cases.preload_case_investigations()
      |> Map.get(:case_investigations)
      |> tids()
      |> assert_eq(~w{investigation1 investigation2}, ignore_order: true)

      [case_investigation1, case_investigation2] =
        alice
        |> Cases.preload_case_investigations()
        |> Map.get(:case_investigations)

      assert_eq(case_investigation1.initiated_by_id, lab_result1.id)
      assert_eq(case_investigation2.initiated_by_id, lab_result2.id)
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab_result1", ~D[2020-10-27]) |> Cases.create_lab_result!()
      {default_attrs, _} = Test.Fixtures.case_investigation_attrs(person, lab_result, user, "case_investigation")
      Cases.change_case_investigation(%CaseInvestigation{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "person_id is required", do: assert_invalid(new_changeset(person_id: nil))
    test "initiated_by_id is required", do: assert_invalid(new_changeset(initiated_by_id: nil))
  end
end
