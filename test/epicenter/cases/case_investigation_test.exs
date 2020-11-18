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
          {:completed_interview_at, :utc_datetime},
          {:discontinue_reason, :string},
          {:discontinued_at, :utc_datetime},
          {:id, :binary_id},
          {:initiating_lab_result_id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:interview_proxy_name, :string},
          {:isolation_concluded_at, :utc_datetime},
          {:isolation_conclusion_reason, :string},
          {:isolation_monitoring_end_date, :date},
          {:isolation_monitoring_start_date, :date},
          {:isolation_clearance_order_sent_date, :date},
          {:isolation_order_sent_date, :date},
          {:name, :string},
          {:person_id, :binary_id},
          {:seq, :integer},
          {:started_at, :utc_datetime},
          {:symptom_onset_date, :date},
          {:symptoms, {:array, :string}},
          {:tid, :string},
          {:updated_at, :utc_datetime}
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

      assert_eq(case_investigation1.initiating_lab_result_id, lab_result1.id)
      assert_eq(case_investigation2.initiating_lab_result_id, lab_result2.id)
    end

    test "includes non-deleted exposures" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
      case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation") |> Cases.create_case_investigation!()
      {:ok, exposure} = {Test.Fixtures.exposure_attrs(case_investigation, "exposure"), Test.Fixtures.admin_audit_meta()} |> Cases.create_exposure()

      {:ok, _} =
        {Test.Fixtures.exposure_attrs(case_investigation, "exposure", %{deleted_at: NaiveDateTime.utc_now()}), Test.Fixtures.admin_audit_meta()}
        |> Cases.create_exposure()

      case_investigation = case_investigation.id |> Cases.get_case_investigation() |> Cases.preload_exposures()
      assert case_investigation.exposures |> Enum.map(& &1.id) == [exposure.id]
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
    test "initiating_lab_result_id is required", do: assert_invalid(new_changeset(initiating_lab_result_id: nil))
  end

  describe "case investigation status" do
    test "pending by default", do: assert(CaseInvestigation.status(%{}) == :pending)
    test "discontinued when discontinued_at", do: assert(CaseInvestigation.status(%{discontinued_at: ~D[2020-08-01]}) == :discontinued)
    test "started when started_at", do: assert(CaseInvestigation.status(%{started_at: ~D[2020-08-01]}) == :started)

    test "completed interview when completed_interview_at",
      do: assert(CaseInvestigation.status(%{completed_interview_at: ~D[2020-08-01]}) == :completed_interview)
  end

  describe "isolation monitoring status" do
    test "pending by default", do: assert(CaseInvestigation.isolation_monitoring_status(%{}) == :pending)

    test "ongoing when isolation_monitoring_start_date",
      do: assert(CaseInvestigation.isolation_monitoring_status(%{isolation_monitoring_start_date: ~D[2020-08-01]}) == :ongoing)

    test "concluded when isolation_concluded_at is present",
      do:
        assert(
          CaseInvestigation.isolation_monitoring_status(%{isolation_monitoring_start_date: ~D[2020-08-01], isolation_concluded_at: ~D[2020-08-02]}) ==
            :concluded
        )
  end
end
