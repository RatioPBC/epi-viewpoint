defmodule EpiViewpoint.ContactInvestigations.ContactInvestigationTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.Cases
  alias EpiViewpoint.ContactInvestigations.ContactInvestigation
  alias EpiViewpoint.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        ContactInvestigation,
        [
          {:clinical_status, :string},
          {:deleted_at, :utc_datetime},
          {:exposed_on, :date},
          {:exposed_person_id, :binary_id},
          {:exposing_case_id, :binary_id},
          {:guardian_name, :string},
          {:guardian_phone, :string},
          {:household_member, :boolean},
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:interview_completed_at, :utc_datetime},
          {:interview_discontinue_reason, :string},
          {:interview_discontinued_at, :utc_datetime},
          {:interview_proxy_name, :string},
          {:interview_started_at, :utc_datetime},
          {:interview_status, :string},
          {:most_recent_date_together, :date},
          {:quarantine_conclusion_reason, :string},
          {:quarantine_concluded_at, :utc_datetime},
          {:quarantine_monitoring_ends_on, :date},
          {:quarantine_monitoring_starts_on, :date},
          {:quarantine_monitoring_status, :string},
          {:relationship_to_case, :string},
          {:seq, :integer},
          {:symptoms, {:array, :string}},
          {:tid, :string},
          {:under_18, :boolean},
          {:updated_at, :utc_datetime}
        ]
      )
    end
  end

  defp new_changeset(attr_updates \\ %{}) do
    person = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, @admin, "lab_result1", ~D[2020-10-27]) |> Cases.create_lab_result!()
    exposing_case = Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "case_investigation") |> Cases.create_case_investigation!()

    default_attrs = Test.Fixtures.contact_investigation_attrs("validation example", %{exposing_case_id: exposing_case.id})
    ContactInvestigation.changeset(%ContactInvestigation{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
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

  describe "contact investigation interview status using generated column" do
    test "pending by default" do
      {:ok, contact_investigation} = new_changeset() |> Repo.insert()
      assert contact_investigation.interview_status == "pending"
    end

    test "discontinued when interview_discontinued_at is not null" do
      {:ok, contact_investigation} = new_changeset(interview_discontinued_at: DateTime.utc_now()) |> Repo.insert()
      assert contact_investigation.interview_status == "discontinued"
    end

    test "started when interview_started_at is not null" do
      {:ok, contact_investigation} = new_changeset(%{interview_started_at: DateTime.utc_now()}) |> Repo.insert()
      assert contact_investigation.interview_status == "started"
    end

    test "completed when interview_completed_interview is not null and interview_started_at is not null" do
      {:ok, contact_investigation} =
        %{interview_completed_at: DateTime.utc_now(), interview_started_at: DateTime.utc_now()}
        |> new_changeset()
        |> Repo.insert()

      assert contact_investigation.interview_status == "completed"
    end
  end

  describe "contact investigation quarantine monitoring status using generated column" do
    test "pending by default" do
      {:ok, contact_investigation} = new_changeset() |> Repo.insert()
      assert contact_investigation.quarantine_monitoring_status == "pending"
    end

    test "pending when interview status is completed" do
      {:ok, contact_investigation} =
        %{interview_completed_at: DateTime.utc_now(), interview_started_at: DateTime.utc_now()}
        |> new_changeset()
        |> Repo.insert()

      assert contact_investigation.interview_status == "completed"
      assert contact_investigation.quarantine_monitoring_status == "pending"
    end

    test "ongoing when quarantine monitoring starts on is not null" do
      {:ok, contact_investigation} =
        %{quarantine_monitoring_starts_on: DateTime.utc_now(), interview_discontinued_at: DateTime.utc_now()}
        |> new_changeset()
        |> Repo.insert()

      assert contact_investigation.quarantine_monitoring_status == "ongoing"
    end

    test "concluded when quarantine monitoring has been completed" do
      {:ok, contact_investigation} =
        %{
          interview_completed_at: DateTime.utc_now(),
          quarantine_monitoring_starts_on: DateTime.utc_now(),
          quarantine_concluded_at: DateTime.utc_now()
        }
        |> new_changeset()
        |> Repo.insert()

      assert contact_investigation.quarantine_monitoring_status == "concluded"
    end
  end
end
