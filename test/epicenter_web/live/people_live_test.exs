defmodule EpicenterWeb.PeopleLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Extra
  alias Epicenter.Test
  alias EpicenterWeb.PeopleLive
  alias EpicenterWeb.Test.Pages

  @admin Test.Fixtures.admin()

  setup [:register_and_log_in_user, :create_people_and_lab_results]

  describe "rendering" do
    test("disconnected and connected render", %{conn: conn}, do: Pages.People.visit(conn) |> Pages.People.assert_here())

    test "users can limit shown people to just those assigned to themselves", %{conn: conn, people: [alice | _], user: user} do
      {:ok, _} = Cases.assign_user_to_people(user_id: user.id, people_ids: [alice.id], audit_meta: Test.Fixtures.admin_audit_meta())

      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Latest test result", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "Detected, 3 days ago", "", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", "", user.name]
      ])
      |> Pages.People.assert_unchecked("[data-tid=assigned-to-me-checkbox]")
      |> Pages.People.click_assigned_to_me_checkbox()
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Latest test result", "Investigation status", "Assignee"],
        ["", "Alice Testuser", "", "positive, 1 day ago", "", user.name]
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
      {:ok, _} = Cases.assign_user_to_people(user_id: context.user.id, people_ids: [alice.id], audit_meta: Test.Fixtures.admin_audit_meta())

      Pages.People.visit(conn)
      |> Pages.People.click_person_checkbox(person: alice, value: "on")
      |> Pages.People.click_person_checkbox(person: billy, value: "on")
      |> Pages.People.click_assigned_to_me_checkbox()
      |> Pages.People.change_form(%{"user" => context.assignee.id})

      Cases.get_people([alice.id, billy.id])
      |> Euclid.Extra.Enum.pluck(:assigned_to_id)
      |> assert_eq([context.assignee.id, nil])
    end

    test "user can be assigned to people", %{assignee: assignee, conn: conn, people: [alice | _]} do
      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Latest test result", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "Detected, 3 days ago", "", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", "", ""]
      ])
      |> Pages.People.assert_assign_dropdown_options(data_role: "users", expected: ["", "Unassigned", "assignee", "fixture admin", "user"])
      |> Pages.People.assert_unchecked("[data-tid=#{alice.tid}]")
      |> Pages.People.click_person_checkbox(person: alice, value: "on")
      |> Pages.People.assert_checked("[data-tid=alice.tid]")
      |> Pages.People.change_form(%{"user" => assignee.id})
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Latest test result", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "Detected, 3 days ago", "", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", "", "assignee"]
      ])
      |> Pages.People.assert_unchecked("[data-tid=#{alice.tid}]")
    end

    test "users can be unassigned from people", %{assignee: assignee, conn: conn, people: [alice, billy | _], user: user} do
      Cases.assign_user_to_people(user_id: assignee.id, people_ids: [alice.id, billy.id], audit_meta: Test.Fixtures.audit_meta(user))

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

      Cases.get_people([alice.id, billy.id])
      |> Cases.preload_assigned_to()
      |> Euclid.Extra.Enum.pluck(:assigned_to)
      |> assert_eq([nil, nil])
    end

    test "shows assignee update from different client", %{assignee: assignee, conn: conn, people: [alice | _]} do
      view =
        Pages.People.visit(conn)
        |> Pages.People.assert_table_contents([
          ["", "Name", "ID", "Latest test result", "Investigation status", "Assignee"],
          ["", "Billy Testuser", "billy-id", "Detected, 3 days ago", "", ""],
          ["", "Alice Testuser", "", "positive, 1 day ago", "", ""]
        ])

      updated_people = [%{alice | assigned_to: assignee}]
      Cases.broadcast_people(updated_people)

      view
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Latest test result", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "Detected, 3 days ago", "", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", "", "assignee"]
      ])
    end

    test "shows people with positive lab tests", %{conn: conn} do
      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Latest test result"],
          ["Billy Testuser", "Detected, 3 days ago"],
          ["Alice Testuser", "positive, 1 day ago"]
        ],
        columns: ["Name", "Latest test result"]
      )
    end

    test "shows case investigation statuses", %{conn: conn} do
      Pages.People.visit(conn)
      |> Pages.People.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Billy Testuser", ""],
          ["Alice Testuser", ""]
        ],
        columns: ["Name", "Investigation status"]
      )
    end

    test "shows a reload message after broadcasting with a new list of people", %{conn: conn, user: user} do
      # start with existing people
      view =
        Pages.People.visit(conn)
        |> Pages.People.assert_table_contents([
          ["", "Name", "ID", "Latest test result", "Investigation status", "Assignee"],
          ["", "Billy Testuser", "billy-id", "Detected, 3 days ago", "", ""],
          ["", "Alice Testuser", "", "positive, 1 day ago", "", ""]
        ])
        |> Pages.People.assert_reload_message("")

      people = import_three_people_with_two_positive_results(user)
      Cases.broadcast_people(people)

      # show a button to make the people visible
      # TODO: should we actually state 2 people here?
      Pages.People.assert_reload_message(view, "An import was completed. Show new people.")
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Latest test result", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "Detected, 3 days ago", "", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", "", ""]
      ])
      |> Pages.People.click_reload_people()
      |> Pages.People.assert_reload_message("")
      |> Pages.People.assert_table_contents([
        ["", "Name", "ID", "Latest test result", "Investigation status", "Assignee"],
        ["", "Billy Testuser", "billy-id", "Detected, 3 days ago", "", ""],
        ["", "David Testuser", "billy-id", "Detected, 3 days ago", "", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", "", ""],
        ["", "Cindy Testuser", "", "positive, 1 day ago", "", ""]
      ])

      # refresh the people
      Cases.broadcast_people(people)

      # TODO: we probably state 0 people here, as the test previously did...
      Pages.People.assert_reload_message(view, "An import was completed. Show new people.")
    end
  end

  describe "save button" do
    test "it is disabled by default", %{conn: conn} do
      {:ok, index_live, _} = live(conn, "/people")
      assert_disabled(index_live, "[data-role=users]")
    end

    test "it is enabled after selecting a person", %{conn: conn, people: [alice | _]} do
      {:ok, index_live, _} = live(conn, "/people")
      assert_disabled(index_live, "[data-role=users]")
      index_live |> element("[data-tid=#{alice.tid}]") |> render_click(%{"person-id" => alice.id, "value" => "on"})
      assert_enabled(index_live, "[data-role=users]")
    end
  end

  describe "full_name" do
    defp wrap(demo_attrs) do
      {:ok, person} = Test.Fixtures.person_attrs(@admin, "test") |> Test.Fixtures.add_demographic_attrs(demo_attrs) |> Cases.create_person()
      person
    end

    test "renders first and last name",
      do: assert(PeopleLive.full_name(wrap(%{first_name: "First", last_name: "TestuserLast"})) == "First TestuserLast")

    test "when there's just a first name",
      do: assert(PeopleLive.full_name(wrap(%{first_name: "First", last_name: nil})) == "First")

    test "when there's just a last name",
      do: assert(PeopleLive.full_name(wrap(%{first_name: nil, last_name: "TestuserLast"})) == "TestuserLast")

    test "when first name is blank",
      do: assert(PeopleLive.full_name(wrap(%{first_name: "", last_name: "TestuserLast"})) == "TestuserLast")
  end

  describe "latest_result" do
    setup %{user: user} do
      person = user |> Test.Fixtures.person_attrs("person") |> Cases.create_person!()

      [person: person]
    end

    test "when the person has no lab results", %{person: person} do
      assert PeopleLive.latest_result(person) == ""
    end

    test "when there is a result and a sample date", %{person: person, user: user} do
      Test.Fixtures.lab_result_attrs(person, user, "lab-result", ~D[2020-01-01], result: "positive") |> Cases.create_lab_result!()
      assert PeopleLive.latest_result(person) =~ ~r|positive, \d+ days ago|
    end

    test "when there is a lab result and a sample date, but the lab result lacks a result value", %{person: person, user: user} do
      Test.Fixtures.lab_result_attrs(person, user, "lab-result", ~D[2020-01-01], result: nil) |> Cases.create_lab_result!()
      assert PeopleLive.latest_result(person) =~ ~r|unknown, \d+ days ago|
    end

    test "when there is a result and no sample date", %{person: person, user: user} do
      Test.Fixtures.lab_result_attrs(person, user, "lab-result", nil, result: "positive") |> Cases.create_lab_result!()
      assert PeopleLive.latest_result(person) =~ ~r|positive, unknown date|
    end

    test "when there is a lab result and no result or sample date", %{person: person, user: user} do
      Test.Fixtures.lab_result_attrs(person, user, "lab-result", nil, result: nil) |> Cases.create_lab_result!()
      assert PeopleLive.latest_result(person) =~ ~r|unknown, unknown date|
    end
  end

  defp create_people_and_lab_results(%{user: user} = _context) do
    assignee = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "assignee") |> Accounts.register_user!()

    alice = Test.Fixtures.person_attrs(user, "alice", external_id: nil) |> Cases.create_person!()
    Test.Fixtures.lab_result_attrs(alice, user, "alice-result-1", Extra.Date.days_ago(1), result: "positive") |> Cases.create_lab_result!()
    Test.Fixtures.lab_result_attrs(alice, user, "alice-result-2", Extra.Date.days_ago(2), result: "negative") |> Cases.create_lab_result!()

    billy = Test.Fixtures.person_attrs(user, "billy") |> Test.Fixtures.add_demographic_attrs(%{external_id: "billy-id"}) |> Cases.create_person!()
    Test.Fixtures.lab_result_attrs(billy, user, "billy-result-1", Extra.Date.days_ago(3), result: "Detected") |> Cases.create_lab_result!()

    nancy = Test.Fixtures.person_attrs(user, "nancy") |> Test.Fixtures.add_demographic_attrs(%{external_id: "nancy-id"}) |> Cases.create_person!()
    Test.Fixtures.lab_result_attrs(nancy, user, "nancy-result-1", Extra.Date.days_ago(3), result: "negative") |> Cases.create_lab_result!()

    people = [alice, billy, nancy] |> Cases.preload_assigned_to() |> Cases.preload_lab_results() |> Cases.preload_case_investigations()
    [assignee: assignee, people: people, user: user]
  end

  defp import_three_people_with_two_positive_results(user) do
    cindy = Test.Fixtures.person_attrs(user, "cindy") |> Cases.create_person!()
    Test.Fixtures.lab_result_attrs(cindy, user, "cindy-result-1", Extra.Date.days_ago(1), result: "positive") |> Cases.create_lab_result!()
    Test.Fixtures.lab_result_attrs(cindy, user, "cindy-result-2", Extra.Date.days_ago(2), result: "negative") |> Cases.create_lab_result!()

    david = Test.Fixtures.person_attrs(user, "david") |> Test.Fixtures.add_demographic_attrs(%{external_id: "billy-id"}) |> Cases.create_person!()
    Test.Fixtures.lab_result_attrs(david, user, "david-result-1", Extra.Date.days_ago(3), result: "Detected") |> Cases.create_lab_result!()

    emily = Test.Fixtures.person_attrs(user, "emily") |> Test.Fixtures.add_demographic_attrs(%{external_id: "nancy-id"}) |> Cases.create_person!()
    Test.Fixtures.lab_result_attrs(emily, user, "emily-result-1", Extra.Date.days_ago(3), result: "negative") |> Cases.create_lab_result!()

    [cindy, david, emily] |> Cases.preload_assigned_to() |> Cases.preload_lab_results() |> Cases.preload_case_investigations()
  end
end
