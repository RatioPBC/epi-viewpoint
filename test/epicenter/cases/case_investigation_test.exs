defmodule Epicenter.Cases.CaseInvestigationTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]
  import ExUnit.CaptureLog

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias Epicenter.Test.AuditLogAssertions

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        CaseInvestigation,
        [
          {:clinical_status, :string},
          {:id, :binary_id},
          {:initiating_lab_result_id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:interview_completed_at, :utc_datetime},
          {:interview_discontinue_reason, :string},
          {:interview_discontinued_at, :utc_datetime},
          {:interview_proxy_name, :string},
          {:interview_started_at, :utc_datetime},
          {:interview_status, :string},
          {:isolation_clearance_order_sent_on, :date},
          {:isolation_concluded_at, :utc_datetime},
          {:isolation_conclusion_reason, :string},
          {:isolation_monitoring_ends_on, :date},
          {:isolation_monitoring_starts_on, :date},
          {:isolation_monitoring_status, :string},
          {:isolation_order_sent_on, :date},
          {:name, :string},
          {:person_id, :binary_id},
          {:seq, :integer},
          {:symptom_onset_on, :date},
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

    test "includes non-deleted contact investigations" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
      case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation") |> Cases.create_case_investigation!()

      {:ok, contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("contact_investigation_a", %{exposing_case_id: case_investigation.id}),
         Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      {:ok, _} =
        {Test.Fixtures.contact_investigation_attrs("contact_investigation_b", %{
           exposing_case_id: case_investigation.id,
           deleted_at: NaiveDateTime.utc_now()
         }), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      case_investigation = Cases.get_case_investigation(case_investigation.id, @admin) |> Cases.preload_contact_investigations(@admin)

      assert case_investigation.contact_investigations |> Enum.map(& &1.id) == [contact_investigation.id]
    end
  end

  describe "changeset" do
    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "person_id is required", do: assert_invalid(new_changeset(person_id: nil))
    test "initiating_lab_result_id is required", do: assert_invalid(new_changeset(initiating_lab_result_id: nil))
  end

  describe "case investigation interview status using generated column" do
    test "pending by default" do
      {:ok, case_investigation} = new_changeset(%{}) |> Repo.insert()
      assert case_investigation.interview_status == "pending"
    end

    test "discontinued when interview_discontinued_at is not null" do
      {:ok, case_investigation} = %{interview_discontinued_at: DateTime.utc_now()} |> new_changeset() |> Repo.insert()
      assert case_investigation.interview_status == "discontinued"
    end

    test "started when interview_started_at is not null" do
      {:ok, case_investigation} = %{interview_started_at: DateTime.utc_now()} |> new_changeset() |> Repo.insert()
      assert case_investigation.interview_status == "started"
    end

    test "completed when interview_completed_interview is not null and interview_started_at is not null" do
      {:ok, case_investigation} =
        %{interview_completed_at: DateTime.utc_now(), interview_started_at: DateTime.utc_now()}
        |> new_changeset()
        |> Repo.insert()

      assert case_investigation.interview_status == "completed"
    end
  end

  describe "case investigation isolation monitoring status using generated column" do
    test "pending by default" do
      {:ok, empty_case_investigation} = new_changeset(%{}) |> Repo.insert()
      assert empty_case_investigation.isolation_monitoring_status == "pending"
    end

    test "pending when interview is started" do
      {:ok, interview_started_case_investigation} = new_changeset(%{interview_started_at: DateTime.utc_now()}) |> Repo.insert()

      assert interview_started_case_investigation.isolation_monitoring_status == "pending"
    end

    test "pending when interview is complete and monitoring is not started" do
      {:ok, interview_completed_case_investigation} =
        new_changeset(%{interview_started_at: DateTime.utc_now(), interview_completed_at: DateTime.utc_now()}) |> Repo.insert()

      assert interview_completed_case_investigation.isolation_monitoring_status == "pending"
    end

    test "pending when interview is discontinued" do
      {:ok, interview_discontinued_case_investigation} =
        %{
          interview_started_at: DateTime.utc_now(),
          interview_discontinued_at: DateTime.utc_now()
        }
        |> new_changeset()
        |> Repo.insert()

      assert interview_discontinued_case_investigation.isolation_monitoring_status == "pending"
    end

    test "ongoing when investigation has monitoring started on" do
      {:ok, monitoring_started_case_investigation} =
        %{
          interview_started_at: DateTime.utc_now(),
          interview_completed_at: DateTime.utc_now(),
          isolation_monitoring_starts_on: ~D[2020-08-01]
        }
        |> new_changeset()
        |> Repo.insert()

      assert monitoring_started_case_investigation.isolation_monitoring_status == "ongoing"
    end

    test "concluded when investigation has monitoring started on and concluded on" do
      {:ok, monitoring_concluded_case_investigation} =
        %{
          interview_started_at: DateTime.utc_now(),
          interview_completed_at: DateTime.utc_now(),
          isolation_monitoring_starts_on: ~D[2020-08-01],
          isolation_concluded_at: DateTime.utc_now()
        }
        |> new_changeset()
        |> Repo.insert()

      assert monitoring_concluded_case_investigation.isolation_monitoring_status == "concluded"
    end
  end

  describe "fetching filtered lists of case investigations" do
    setup do
      alice = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      create_case_investigation(alice, @admin, "pending-case-investigation", ~D[2021-01-28], %{})

      bob = Test.Fixtures.person_attrs(@admin, "bob") |> Cases.create_person!()

      create_case_investigation(bob, @admin, "started-case-investigation", nil, %{
        interview_started_at: NaiveDateTime.utc_now(),
        clinical_status: "symptomatic"
      })

      create_case_investigation(bob, @admin, "interview-completed-case-investigation", nil, %{
        interview_completed_at: ~U[2020-10-31 23:03:07Z],
        interview_started_at: ~U[2020-10-31 22:03:07Z]
      })

      cindy = Test.Fixtures.person_attrs(@admin, "cindy") |> Cases.create_person!()

      create_case_investigation(cindy, @admin, "discontinued-case-investigation", nil, %{
        interview_started_at: ~U[2020-10-31 22:03:07Z],
        interview_discontinued_at: ~U[2020-10-31 23:03:07Z],
        interview_discontinue_reason: "Unable to reach"
      })

      david = Test.Fixtures.person_attrs(@admin, "david") |> Cases.create_person!()

      create_case_investigation(david, @admin, "isolation-monitoring-started-case-investigation", nil, %{
        interview_completed_at: ~U[2020-10-05 19:57:00Z],
        interview_started_at: ~U[2020-10-05 18:57:00Z],
        isolation_monitoring_starts_on: ~D[2020-11-05],
        isolation_monitoring_ends_on: ~D[2020-11-15]
      })

      eva = Test.Fixtures.person_attrs(@admin, "eva") |> Cases.create_person!()

      create_case_investigation(eva, @admin, "isolation-monitoring-completed-case-investigation", nil, %{
        interview_completed_at: ~U[2020-10-05 19:57:00Z],
        interview_started_at: ~U[2020-10-05 18:57:00Z],
        isolation_concluded_at: ~U[2020-11-15 19:57:00Z],
        isolation_conclusion_reason: "successfully_completed",
        isolation_monitoring_ends_on: ~D[2020-11-15],
        isolation_monitoring_starts_on: ~D[2020-11-05]
      })

      create_archived_person(
        "frank",
        %{},
        "ongoing-interview"
      )

      create_archived_person(
        "george",
        %{
          interview_started_at: NaiveDateTime.utc_now(),
          clinical_status: "symptomatic"
        },
        "ongoing-interview"
      )

      create_archived_person(
        "haley",
        %{
          interview_completed_at: ~U[2020-10-31 23:03:07Z],
          interview_started_at: ~U[2020-10-31 22:03:07Z]
        },
        "ongoing-interview"
      )

      create_archived_person(
        "ingrid",
        %{
          interview_started_at: ~U[2020-10-31 22:03:07Z],
          interview_discontinued_at: ~U[2020-10-31 23:03:07Z],
          interview_discontinue_reason: "Unable to reach"
        },
        "ongoing-interview"
      )

      create_archived_person(
        "james",
        %{
          interview_completed_at: ~U[2020-10-05 19:57:00Z],
          interview_started_at: ~U[2020-10-05 18:57:00Z],
          isolation_monitoring_starts_on: ~D[2020-11-05],
          isolation_monitoring_ends_on: ~D[2020-11-15]
        },
        "ongoing-interview"
      )

      create_archived_person(
        "kris",
        %{
          interview_completed_at: ~U[2020-10-05 19:57:00Z],
          interview_started_at: ~U[2020-10-05 18:57:00Z],
          isolation_concluded_at: ~U[2020-11-15 19:57:00Z],
          isolation_conclusion_reason: "successfully_completed",
          isolation_monitoring_ends_on: ~D[2020-11-15],
          isolation_monitoring_starts_on: ~D[2020-11-05]
        },
        "ongoing-interview"
      )

      meryl = Test.Fixtures.person_attrs(@admin, "meryl") |> Cases.create_person!()

      create_case_investigation(meryl, @admin, "merged-person", nil, %{
        interview_completed_at: ~U[2020-10-05 19:57:00Z],
        interview_started_at: ~U[2020-10-05 18:57:00Z],
        isolation_concluded_at: ~U[2020-11-15 19:57:00Z],
        isolation_conclusion_reason: "successfully_completed",
        isolation_monitoring_ends_on: ~D[2020-11-15],
        isolation_monitoring_starts_on: ~D[2020-11-05]
      })

      Cases.merge_people([meryl.id], alice.id, @admin, Test.Fixtures.admin_audit_meta())

      user = Test.Fixtures.user_attrs(@admin, "the-user") |> Accounts.register_user!()

      [user: user, alice: alice, bob: bob, cindy: cindy, david: david, eva: eva]
    end

    defp create_archived_person(tid, case_investigation_attrs, state) do
      person = Test.Fixtures.person_attrs(@admin, tid) |> Cases.create_person!()

      create_case_investigation(person, @admin, "archived-case-investigation-#{state}", nil, case_investigation_attrs)

      Cases.archive_person(person.id, @admin, Test.Fixtures.admin_audit_meta())
    end

    test "fetching case investigations for the 'pending interview' tab", %{user: user, alice: alice} do
      capture_log(fn ->
        actual = Cases.list_case_investigations(:pending_interview, user: user) |> tids

        assert actual == [
                 "pending-case-investigation"
               ]
      end)
      |> AuditLogAssertions.assert_viewed_people(user, [alice])
    end

    test "fetching case investigations for the ongoing interview tab", %{user: user, bob: bob} do
      capture_log(fn ->
        actual = Cases.list_case_investigations(:ongoing_interview, user: user) |> tids

        assert actual == [
                 "started-case-investigation"
               ]
      end)
      |> AuditLogAssertions.assert_viewed_people(user, [bob])
    end

    test "fetching case investigations for the isolation monitoring tab", %{user: user, bob: bob, david: david} do
      capture_log(fn ->
        actual = Cases.list_case_investigations(:isolation_monitoring, user: user) |> tids

        assert actual == [
                 "interview-completed-case-investigation",
                 "isolation-monitoring-started-case-investigation"
               ]
      end)
      |> AuditLogAssertions.assert_viewed_people(user, [bob, david])
    end

    test "fetching case investigations for the all tab",
         %{user: user, alice: alice, bob: bob, cindy: cindy, david: david, eva: eva} do
      capture_log(fn ->
        actual = Cases.list_case_investigations(:all, user: user) |> tids

        assert actual == [
                 "pending-case-investigation",
                 "started-case-investigation",
                 "interview-completed-case-investigation",
                 "discontinued-case-investigation",
                 "isolation-monitoring-started-case-investigation",
                 "isolation-monitoring-completed-case-investigation"
               ]
      end)
      |> AuditLogAssertions.assert_viewed_people(user, [alice, bob, cindy, david, eva])
    end
  end

  describe "sorting lists of case investigations" do
    test "'pending interview' sorts by assignee name, then tie-breaks with most recent positive lab result near the top" do
      first_assignee = Test.Fixtures.user_attrs(@admin, "assignee") |> Accounts.register_user!()
      second_assignee = Test.Fixtures.user_attrs(@admin, "second_assignee") |> Accounts.register_user!()

      # Assigned last
      setup_case_investigation_with_assigns(@admin, second_assignee, "assigned_last",
        result: "pOsItIvE",
        sampled_on: ~D[2020-06-06]
      )

      # Assigned middle
      setup_case_investigation_with_assigns(@admin, first_assignee, "assigned_middle",
        result: "pOsItIvE",
        sampled_on: ~D[2020-06-05]
      )

      # Assigned first
      setup_case_investigation_with_assigns(@admin, first_assignee, "assigned_first",
        result: "DeTectEd",
        sampled_on: ~D[2020-06-08]
      )

      # Unassigned last
      setup_case_investigation_with_assigns(@admin, nil, "unassigned_last",
        result: "negative",
        sampled_on: ~D[2020-06-03]
      )

      # Unassigned first
      setup_case_investigation_with_assigns(@admin, nil, "unassigned_first",
        result: "positive",
        sampled_on: ~D[2020-06-04]
      )

      CaseInvestigation.Query.list(:pending_interview)
      |> Epicenter.Repo.all()
      |> tids()
      |> assert_eq(~w{unassigned_first_case_investigation
        unassigned_last_case_investigation
        assigned_first_case_investigation
        assigned_middle_case_investigation
        assigned_last_case_investigation})
    end

    test "'ongoing interview' sorts by assignee name, then tie-breaks with most recent positive lab result near the top" do
      first_assignee = Test.Fixtures.user_attrs(@admin, "assignee") |> Accounts.register_user!()
      second_assignee = Test.Fixtures.user_attrs(@admin, "second_assignee") |> Accounts.register_user!()

      # Assigned last
      setup_case_investigation_with_assigns(@admin, second_assignee, "assigned_last",
        result: "positive",
        sampled_on: ~D[2020-06-04],
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      )

      # Assigned middle
      setup_case_investigation_with_assigns(@admin, first_assignee, "assigned_middle",
        result: "positive",
        sampled_on: ~D[2020-06-04],
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      )

      # Assigned first
      setup_case_investigation_with_assigns(@admin, first_assignee, "assigned_first",
        result: "DeTectEd",
        sampled_on: ~D[2020-06-08],
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      )

      # Unassigned last
      setup_case_investigation_with_assigns(@admin, nil, "unassigned_last",
        result: "positive",
        sampled_on: ~D[2020-05-03],
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      )

      # Unassigned first
      setup_case_investigation_with_assigns(@admin, nil, "unassigned_first",
        result: "positive",
        sampled_on: ~D[2020-06-03],
        interview_started_at: ~U[2020-01-01 22:03:07Z]
      )

      CaseInvestigation.Query.list(:ongoing_interview)
      |> Epicenter.Repo.all()
      |> tids()
      |> assert_eq(~w{unassigned_first_case_investigation
        unassigned_last_case_investigation
        assigned_first_case_investigation
        assigned_middle_case_investigation
        assigned_last_case_investigation})
    end

    test "'isolation monitoring' sorts by isolation_monitoring_status, then tie-breaks with monitoring-end-time" do
      setup_person_with_case_investigation(@admin, "pending_new", {~U{2020-11-29 10:30:00Z}, nil, nil})
      setup_person_with_case_investigation(@admin, "pending_old", {~U{2020-11-21 10:30:00Z}, nil, nil})
      setup_person_with_case_investigation(@admin, "ongoing_ends_soon", {~U{2020-11-21 10:30:00Z}, ~D{2020-11-25}, ~D{2020-12-05}})

      # Adds a duplicate case investigation for a person - we should see two rows for the person, one per case investigation
      person = setup_person_with_case_investigation(@admin, "ongoing_ends_later", {~U{2020-11-21 10:30:00Z}, ~D{2020-11-25}, ~D{2020-12-10}})
      setup_person_with_case_investigation(@admin, "duplicate_ongoing_ends_later", {~U{2020-11-21 10:30:00Z}, ~D{2020-11-25}, ~D{2020-12-11}}, person)

      CaseInvestigation.Query.list(:isolation_monitoring)
      |> Epicenter.Repo.all()
      |> tids()
      |> assert_eq(~w{pending_new_case_investigation
        pending_old_case_investigation
        ongoing_ends_soon_case_investigation
        ongoing_ends_later_case_investigation
        duplicate_ongoing_ends_later_case_investigation})
    end

    defp setup_person_with_case_investigation(user, person_tid, case_investigation_attrs, person \\ nil)

    defp setup_person_with_case_investigation(user, person_tid, case_investigation_attrs, nil) do
      person = Test.Fixtures.person_attrs(user, person_tid) |> Cases.create_person!()
      setup_case_investigation(user, person_tid, case_investigation_attrs, person)

      person
    end

    defp setup_person_with_case_investigation(user, person_tid, case_investigation_attrs, person) do
      setup_case_investigation(user, person_tid, case_investigation_attrs, person)
      person
    end

    defp setup_case_investigation(user, person_tid, {interview_completed_at, isolation_monitoring_starts_on, isolation_monitoring_ends_on}, person) do
      lab_result =
        Test.Fixtures.lab_result_attrs(person, user, "#{person_tid}_lab_result", ~D{2020-11-21}, result: "positive") |> Cases.create_lab_result!()

      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "#{person_tid}_case_investigation", %{
        interview_started_at: interview_completed_at,
        interview_completed_at: interview_completed_at,
        isolation_monitoring_starts_on: isolation_monitoring_starts_on,
        isolation_monitoring_ends_on: isolation_monitoring_ends_on
      })
      |> Cases.create_case_investigation!()
    end

    defp setup_case_investigation_with_assigns(user, assignee, assign_tid,
           result: result,
           sampled_on: sampled_on
         ) do
      setup_case_investigation_with_assigns(user, assignee, assign_tid,
        result: result,
        sampled_on: sampled_on,
        interview_started_at: nil
      )
    end

    defp setup_case_investigation_with_assigns(user, assignee, assign_tid,
           result: result,
           sampled_on: sampled_on,
           interview_started_at: interview_started_at
         ) do
      person = Test.Fixtures.person_attrs(user, assign_tid) |> Cases.create_person!()

      person_lab_result = Test.Fixtures.lab_result_attrs(person, user, "#{assign_tid}_2", sampled_on, result: result) |> Cases.create_lab_result!()

      Cases.assign_user_to_people(user: assignee, people_ids: [person.id], audit_meta: Test.Fixtures.admin_audit_meta(), current_user: @admin)

      Test.Fixtures.case_investigation_attrs(person, person_lab_result, user, "#{assign_tid}_case_investigation", %{
        interview_started_at: interview_started_at
      })
      |> Cases.create_case_investigation!()
    end
  end

  defp create_case_investigation(person, user, tid, reported_on, attrs) do
    lab_result =
      Test.Fixtures.lab_result_attrs(person, user, "lab_result_#{tid}", reported_on, %{
        result: "positive",
        request_facility_name: "Big Big Hospital",
        reported_on: reported_on,
        test_type: "PCR"
      })
      |> Cases.create_lab_result!()

    Test.Fixtures.case_investigation_attrs(
      person,
      lab_result,
      user,
      tid,
      %{name: "001"}
      |> Map.merge(attrs)
    )
    |> Cases.create_case_investigation!()
  end

  defp new_changeset(attr_updates) do
    user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab_result1", ~D[2020-10-27]) |> Cases.create_lab_result!()
    {default_attrs, _} = Test.Fixtures.case_investigation_attrs(person, lab_result, user, "case_investigation")
    Cases.change_case_investigation(%CaseInvestigation{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
  end
end
