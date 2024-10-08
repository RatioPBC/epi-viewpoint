defmodule EpiViewpointWeb.PeopleLiveTest do
  use EpiViewpointWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.LabResult
  alias EpiViewpoint.Extra
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.PeopleLive
  alias EpiViewpointWeb.Test.Pages

  setup [:register_and_log_in_user, :create_people_and_lab_results]
  @admin Test.Fixtures.admin()
  @stub_date ~D[2020-10-31]

  describe "rendering" do
    test "records an audit log entry for each person on the page", %{conn: conn, user: user, people: people, lab_results: lab_results} do
      [alice, billy, _nancy] = people
      %{alice_positive: alice_positive, billy_positive: billy_positive} = lab_results
      Test.Fixtures.case_investigation_attrs(alice, alice_positive, user, "") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(billy, billy_positive, user, "") |> Cases.create_case_investigation!()

      AuditLogAssertions.expect_phi_view_logs(4)
      Pages.People.visit(conn)
      AuditLogAssertions.verify_phi_view_logged(user, [alice, billy])
    end

    test "shows unknown as the name of people that lack a first and last name", %{
      conn: conn,
      user: user,
      people: [alice, billy | _],
      lab_results: lab_results
    } do
      %{alice_positive: alice_positive, billy_positive: billy_positive} = lab_results
      Test.Fixtures.case_investigation_attrs(alice, alice_positive, user, "") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(billy, billy_positive, user, "") |> Cases.create_case_investigation!()

      nameless =
        Test.Fixtures.person_attrs(user, "nameless")
        |> Test.Fixtures.add_demographic_attrs(%{first_name: nil, last_name: nil})
        |> Cases.create_person!()

      lab_result =
        Test.Fixtures.lab_result_attrs(nameless, user, "nameless-result-1", Extra.Date.days_ago(4, from: @stub_date), result: "positive")
        |> Cases.create_lab_result!()

      Test.Fixtures.case_investigation_attrs(nameless, lab_result, user, "") |> Cases.create_case_investigation!()

      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Collection date"],
          ["Unknown", "10/27/2020"],
          ["Billy Testuser", "10/28/2020"],
          ["Alice Testuser", "10/30/2020"]
        ],
        columns: ["Name", "Collection date"]
      )
    end

    test "shows case investigation statuses", %{conn: conn, people: people, user: user} do
      [alice, billy, nancy, cindy, david, emily] = people ++ import_three_people_with_two_positive_results(user)

      [
        Test.Fixtures.case_investigation_attrs(alice, LabResult.latest(alice.lab_results), user, "pending-interview"),
        Test.Fixtures.case_investigation_attrs(billy, LabResult.latest(billy.lab_results), user, "ongoing-interview", %{
          interview_started_at: ~U[2020-10-31 23:03:07Z]
        }),
        Test.Fixtures.case_investigation_attrs(cindy, LabResult.latest(cindy.lab_results), user, "concluded-monitoring", %{
          interview_started_at: ~U[2020-10-31 22:03:07Z],
          interview_completed_at: ~U[2020-10-31 23:03:07Z],
          isolation_monitoring_starts_on: ~D[2020-11-03],
          isolation_monitoring_ends_on: ~D[2020-11-13],
          isolation_concluded_at: ~U[2020-10-31 10:30:00Z]
        }),
        Test.Fixtures.case_investigation_attrs(david, LabResult.latest(david.lab_results), user, "ongoing-monitoring", %{
          interview_started_at: ~U[2020-10-31 22:03:07Z],
          interview_completed_at: ~U[2020-10-31 23:03:07Z],
          isolation_monitoring_starts_on: ~D[2020-11-03],
          isolation_monitoring_ends_on: ~D[2020-11-13]
        }),
        Test.Fixtures.case_investigation_attrs(emily, LabResult.latest(emily.lab_results), user, "pending-monitoring", %{
          interview_started_at: ~U[2020-10-31 22:03:07Z],
          interview_completed_at: ~U[2020-10-31 23:03:07Z]
        })
      ]
      |> Enum.map(&Cases.create_case_investigation!/1)

      nancy_positive_lab_result =
        Test.Fixtures.lab_result_attrs(nancy, user, "nancy-positive", Extra.Date.days_ago(3, from: @stub_date), result: "positive")
        |> Cases.create_lab_result!()

      Test.Fixtures.case_investigation_attrs(nancy, nancy_positive_lab_result, user, "discontinued-investigation", %{
        interview_discontinued_at: ~U[2020-10-31 23:03:07Z],
        interview_started_at: ~U[2020-10-31 22:03:07Z]
      })
      |> Cases.create_case_investigation!()

      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Investigation status", "Collection date"],
          ["Billy Testuser", "Ongoing interview", "10/28/2020"],
          ["David Testuser", "Ongoing monitoring (13 days remaining)", "10/28/2020"],
          ["Emily Testuser", "Pending monitoring", "10/28/2020"],
          ["Nancy Testuser", "Discontinued", "10/28/2020"],
          ["Alice Testuser", "Pending interview", "10/30/2020"],
          ["Cindy Testuser", "Concluded monitoring", "10/30/2020"]
        ],
        columns: ["Name", "Investigation status", "Collection date"]
      )
    end

    test "displays the import button if an admin", %{conn: conn, user: user} do
      Accounts.update_user(user, %{admin: true}, Test.Fixtures.audit_meta(@admin))

      Pages.People.visit(conn)
      |> Pages.People.import_button_visible?()
      |> assert()
    end

    test "does not display the import button if non-admin", %{conn: conn, user: user} do
      Accounts.update_user(user, %{admin: false}, Test.Fixtures.audit_meta(@admin))

      Pages.People.visit(conn)
      |> Pages.People.import_button_visible?()
      |> refute()
    end
  end

  describe "filtering" do
    setup %{user: user, people: people} do
      [alice, billy, nancy, cindy, david, emily] = people ++ import_three_people_with_two_positive_results(user)

      [
        Test.Fixtures.case_investigation_attrs(alice, LabResult.latest(alice.lab_results), user, "pending-interview"),
        Test.Fixtures.case_investigation_attrs(billy, LabResult.latest(billy.lab_results), user, "ongoing-interview", %{
          interview_started_at: ~U[2020-10-31 23:03:07Z]
        }),
        Test.Fixtures.case_investigation_attrs(cindy, LabResult.latest(cindy.lab_results), user, "concluded-monitoring", %{
          interview_completed_at: ~U[2020-10-31 23:03:07Z],
          interview_started_at: ~U[2020-10-31 22:03:07Z],
          isolation_concluded_at: ~U[2020-10-31 10:30:00Z],
          isolation_monitoring_ends_on: ~D[2020-11-13],
          isolation_monitoring_starts_on: ~D[2020-11-03]
        }),
        Test.Fixtures.case_investigation_attrs(david, LabResult.latest(david.lab_results), user, "ongoing-monitoring", %{
          interview_completed_at: ~U[2020-10-31 23:03:07Z],
          interview_started_at: ~U[2020-10-31 22:03:07Z],
          isolation_monitoring_ends_on: ~D[2020-11-13],
          isolation_monitoring_starts_on: ~D[2020-11-03]
        }),
        Test.Fixtures.case_investigation_attrs(emily, LabResult.latest(emily.lab_results), user, "pending-monitoring", %{
          interview_completed_at: ~U[2020-10-31 23:03:07Z],
          interview_started_at: ~U[2020-10-31 22:03:07Z]
        })
      ]
      |> Enum.map(&Cases.create_case_investigation!/1)

      [people: [alice, billy, nancy, cindy, david, emily]]
    end

    test "users can limit shown people to just those assigned to themselves", %{conn: conn, people: [alice | _], user: user} do
      {:ok, _} =
        Cases.assign_user_to_people(user_id: user.id, people_ids: [alice.id], audit_meta: Test.Fixtures.admin_audit_meta(), current_user: @admin)

      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Collection date", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "10/28/2020", "Ongoing interview", ""],
        ["", "David Testuser", "david-id", "10/28/2020", "Ongoing monitoring (13 days remaining)", ""],
        ["", "Emily Testuser", "nancy-id", "10/28/2020", "Pending monitoring", ""],
        ["", "Cindy Testuser", "", "10/30/2020", "Concluded monitoring", ""],
        ["", "Alice Testuser", "", "10/30/2020", "Pending interview", user.name]
      ])
      |> Pages.People.assert_unchecked("[data-tid=assigned-to-me-checkbox]")
      |> Pages.People.click_assigned_to_me_checkbox()
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Collection date", "Investigation status", "Assignee"],
        ["", "Alice Testuser", "", "10/30/2020", "Pending interview", user.name]
      ])
      |> Pages.People.assert_checked("[data-tid=assigned-to-me-checkbox]")
    end

    test "people who have been filtered out should not be assigned during a bulk assignment", %{conn: conn, people: [alice, billy | _]} = context do
      # I check person 1 (who is not assigned to me)
      # I check person 2 (who is assigned to me)
      # I toggle so that person 1 is hidden
      # I try to assign to someone
      # that shouldn't change the assignment of person 1
      # but should change the assignment of person 2
      {:ok, _} =
        Cases.assign_user_to_people(
          user_id: context.user.id,
          people_ids: [alice.id],
          audit_meta: Test.Fixtures.admin_audit_meta(),
          current_user: @admin
        )

      Pages.People.visit(conn)
      |> Pages.People.click_person_checkbox(person: alice, value: "on")
      |> Pages.People.click_person_checkbox(person: billy, value: "on")
      |> Pages.People.click_assigned_to_me_checkbox()
      |> Pages.People.change_form(%{"user" => context.assignee.id})

      Cases.get_people([alice.id, billy.id], @admin)
      |> Euclid.Extra.Enum.pluck(:assigned_to_id)
      |> assert_eq([context.assignee.id, nil])
    end

    test "users can filter cases by pending interview status", %{conn: conn} do
      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Billy Testuser", "Ongoing interview"],
          ["David Testuser", "Ongoing monitoring (13 days remaining)"],
          ["Emily Testuser", "Pending monitoring"],
          ["Alice Testuser", "Pending interview"],
          ["Cindy Testuser", "Concluded monitoring"]
        ],
        columns: ["Name", "Investigation status"]
      )
      |> Pages.People.assert_filter_selected(:all)
      |> Pages.People.select_filter(:pending_interview)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Alice Testuser", "Pending interview"]
        ],
        columns: ["Name", "Investigation status"]
      )
    end

    test "users can filter cases by ongoing interview status", %{conn: conn} do
      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Billy Testuser", "Ongoing interview"],
          ["David Testuser", "Ongoing monitoring (13 days remaining)"],
          ["Emily Testuser", "Pending monitoring"],
          ["Alice Testuser", "Pending interview"],
          ["Cindy Testuser", "Concluded monitoring"]
        ],
        columns: ["Name", "Investigation status"]
      )
      |> Pages.People.assert_filter_selected(:all)
      |> Pages.People.select_filter(:ongoing_interview)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Billy Testuser", "Ongoing interview"]
        ],
        columns: ["Name", "Investigation status"]
      )
    end

    test "users can filter cases by people who are pending or ongoing isolation monitoring", %{conn: conn} do
      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Billy Testuser", "Ongoing interview"],
          ["David Testuser", "Ongoing monitoring (13 days remaining)"],
          ["Emily Testuser", "Pending monitoring"],
          ["Alice Testuser", "Pending interview"],
          ["Cindy Testuser", "Concluded monitoring"]
        ],
        columns: ["Name", "Investigation status"]
      )
      |> Pages.People.assert_filter_selected(:all)
      |> Pages.People.select_filter(:isolation_monitoring)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Emily Testuser", "Pending monitoring"],
          ["David Testuser", "Ongoing monitoring (13 days remaining)"]
        ],
        columns: ["Name", "Investigation status"]
      )
    end
  end

  describe "assigning people" do
    test "the assignment dropdown is disabled by default", %{conn: conn} do
      {:ok, index_live, _} = live(conn, "/people")
      Pages.People.assert_assignment_dropdown_disabled(index_live)
    end

    test "the assignment dropdown is enabled after selecting a person", %{conn: conn, user: user, people: [alice | _], lab_results: lab_results} do
      %{alice_positive: alice_positive} = lab_results
      Test.Fixtures.case_investigation_attrs(alice, alice_positive, user, "") |> Cases.create_case_investigation!()

      {:ok, index_live, _} = live(conn, "/people")
      Pages.People.assert_assignment_dropdown_disabled(index_live)
      index_live |> element("[data-tid=#{alice.tid}]") |> render_click(%{"person-id" => alice.id, "value" => "on"})
      Pages.People.assert_assignment_dropdown_enabled(index_live)
    end

    test "user can be assigned to people", %{assignee: assignee, conn: conn, user: user, people: [alice, billy | _], lab_results: lab_results} do
      %{alice_positive: alice_positive, billy_positive: billy_positive} = lab_results
      Test.Fixtures.case_investigation_attrs(alice, alice_positive, user, "") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(billy, billy_positive, user, "") |> Cases.create_case_investigation!()

      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Collection date", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "10/28/2020", "Pending interview", ""],
        ["", "Alice Testuser", "", "10/30/2020", "Pending interview", ""]
      ])
      |> Pages.People.assert_assign_dropdown_options(data_role: "users", expected: ["", "Unassigned", "assignee", "fixture admin", "user"])
      |> Pages.People.assert_unchecked("[data-tid=#{alice.tid}]")
      |> Pages.People.click_person_checkbox(person: alice, value: "on")
      |> Pages.People.assert_checked("[data-tid=alice.tid]")
      |> Pages.People.change_form(%{"user" => assignee.id})
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Collection date", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "10/28/2020", "Pending interview", ""],
        ["", "Alice Testuser", "", "10/30/2020", "Pending interview", "assignee"]
      ])
      |> Pages.People.assert_unchecked("[data-tid=#{alice.tid}]")
      |> Pages.People.assert_assignment_dropdown_disabled()
      |> Pages.People.assert_archive_button_disabled()

      Cases.get_people([alice.id, billy.id], @admin)
      |> Cases.preload_assigned_to()
      |> Euclid.Extra.Enum.pluck(:assigned_to)
      |> assert_eq([assignee, nil])
    end

    test "users can be unassigned from people", %{assignee: assignee, conn: conn, people: [alice, billy | _], lab_results: lab_results, user: user} do
      %{alice_positive: alice_positive, billy_positive: billy_positive} = lab_results
      Test.Fixtures.case_investigation_attrs(alice, alice_positive, user, "") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(billy, billy_positive, user, "") |> Cases.create_case_investigation!()

      Cases.assign_user_to_people(
        user_id: assignee.id,
        people_ids: [alice.id, billy.id],
        audit_meta: Test.Fixtures.audit_meta(user),
        current_user: @admin
      )

      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Assignee"],
          ["Billy Testuser", "assignee"],
          ["Alice Testuser", "assignee"]
        ],
        columns: ["Name", "Assignee"]
      )
      |> Pages.People.click_person_checkbox(person: alice, value: "on")
      |> Pages.People.click_person_checkbox(person: billy, value: "on")
      |> Pages.People.change_form(%{"user" => "-unassigned-"})
      |> Pages.People.assert_unchecked("[data-tid=#{alice.tid}]")
      |> Pages.People.assert_unchecked("[data-tid=#{billy.tid}]")

      Cases.get_people([alice.id, billy.id], @admin)
      |> Cases.preload_assigned_to()
      |> Euclid.Extra.Enum.pluck(:assigned_to)
      |> assert_eq([nil, nil])
    end
  end

  describe "archiving people" do
    test "person can be archived",
         %{conn: conn, user: user, people: [alice | [billy | _]], lab_results: lab_results} do
      %{alice_positive: alice_positive, billy_positive: billy_positive} = lab_results
      Test.Fixtures.case_investigation_attrs(alice, alice_positive, user, "") |> Cases.create_case_investigation!()
      Test.Fixtures.case_investigation_attrs(billy, billy_positive, user, "") |> Cases.create_case_investigation!()

      Pages.People.visit(conn)
      |> Pages.People.assert_archive_button_disabled()
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Collection date", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "10/28/2020", "Pending interview", ""],
        ["", "Alice Testuser", "", "10/30/2020", "Pending interview", ""]
      ])
      |> Pages.People.assert_unchecked("[data-tid=#{alice.tid}]")
      |> Pages.People.click_person_checkbox(person: alice, value: "on")
      |> Pages.People.assert_checked("[data-tid=#{alice.tid}]")
      |> Pages.assert_element_triggers_confirmation_prompt("archive-button", "Are you sure you want to archive 1 person(s)?")
      |> Pages.People.click_archive()
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Collection date", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "10/28/2020", "Pending interview", ""]
      ])
      |> Pages.People.assert_assignment_dropdown_disabled()
      |> Pages.People.assert_archive_button_disabled()
    end
  end

  describe "handle_params" do
    test "blows up when an unknown filter is provided" do
      assert_raise EpiViewpoint.CaseInvestigationFilterError, "Unmatched filter “foo_bar”", fn ->
        PeopleLive.handle_params(%{"filter" => "foo_bar"}, "http://example.com", %Phoenix.LiveView.Socket{})
      end
    end
  end

  defp create_people_and_lab_results(%{user: user} = _context) do
    assignee = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "assignee") |> Accounts.register_user!()

    alice = Test.Fixtures.person_attrs(user, "alice", external_id: nil) |> Cases.create_person!()

    alice_positive =
      Test.Fixtures.lab_result_attrs(alice, user, "alice-positive", Extra.Date.days_ago(1, from: @stub_date), result: "positive")
      |> Cases.create_lab_result!()

    Test.Fixtures.lab_result_attrs(alice, user, "alice-negative", Extra.Date.days_ago(2, from: @stub_date), result: "negative")
    |> Cases.create_lab_result!()

    billy = Test.Fixtures.person_attrs(user, "billy") |> Test.Fixtures.add_demographic_attrs(%{external_id: "billy-id"}) |> Cases.create_person!()

    billy_positive =
      Test.Fixtures.lab_result_attrs(billy, user, "billy-detected", Extra.Date.days_ago(3, from: @stub_date), result: "Detected")
      |> Cases.create_lab_result!()

    nancy = Test.Fixtures.person_attrs(user, "nancy") |> Test.Fixtures.add_demographic_attrs(%{external_id: "nancy-id"}) |> Cases.create_person!()

    Test.Fixtures.lab_result_attrs(nancy, user, "nancy-negative", Extra.Date.days_ago(3, from: @stub_date), result: "negative")
    |> Cases.create_lab_result!()

    people = [alice, billy, nancy] |> Cases.preload_assigned_to() |> Cases.preload_lab_results() |> Cases.preload_case_investigations()
    lab_results = %{alice_positive: alice_positive, billy_positive: billy_positive}
    [assignee: assignee, people: people, user: user, lab_results: lab_results]
  end

  # todo: rename?
  defp import_three_people_with_two_positive_results(user) do
    cindy = Test.Fixtures.person_attrs(user, "cindy") |> Cases.create_person!()

    Test.Fixtures.lab_result_attrs(cindy, user, "cindy-positive", Extra.Date.days_ago(1, from: @stub_date), result: "positive")
    |> Cases.create_lab_result!()

    david = Test.Fixtures.person_attrs(user, "david") |> Test.Fixtures.add_demographic_attrs(%{external_id: "david-id"}) |> Cases.create_person!()

    Test.Fixtures.lab_result_attrs(david, user, "david-positive", Extra.Date.days_ago(3, from: @stub_date), result: "positive")
    |> Cases.create_lab_result!()

    emily = Test.Fixtures.person_attrs(user, "emily") |> Test.Fixtures.add_demographic_attrs(%{external_id: "nancy-id"}) |> Cases.create_person!()

    Test.Fixtures.lab_result_attrs(emily, user, "emily-positive", Extra.Date.days_ago(3, from: @stub_date), result: "positive")
    |> Cases.create_lab_result!()

    [cindy, david, emily] |> Cases.preload_assigned_to() |> Cases.preload_lab_results() |> Cases.preload_case_investigations()
  end
end
