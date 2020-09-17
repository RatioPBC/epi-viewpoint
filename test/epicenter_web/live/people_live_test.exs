defmodule EpicenterWeb.PeopleLiveTest do
  use EpicenterWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Extra
  alias Epicenter.Test
  alias EpicenterWeb.PeopleLive

  describe "rendering" do
    defp table_contents(index_live, opts \\ []),
      do: index_live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "people"))

    defp create_people_and_lab_results() do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      assignee = Test.Fixtures.user_attrs("assignee") |> Accounts.create_user!()

      alice = Test.Fixtures.person_attrs(user, "alice", external_id: nil) |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, "alice-result-1", Extra.Date.days_ago(1), result: "positive") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, "alice-result-2", Extra.Date.days_ago(2), result: "negative") |> Cases.create_lab_result!()

      billy = Test.Fixtures.person_attrs(user, "billy", external_id: "billy-id") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(billy, "billy-result-1", Extra.Date.days_ago(3), result: "negative") |> Cases.create_lab_result!()
      [users: [user, assignee], people: [alice, billy] |> Cases.preload_assigned_to() |> Cases.preload_lab_results()]
    end

    test "disconnected and connected render", %{conn: conn} do
      {:ok, index_live, disconnected_html} = live(conn, "/people")

      assert_has_role(disconnected_html, "people-page")
      assert_has_role(index_live, "people-page")
    end

    test "user can be assigned to people", %{conn: conn} do
      [users: [_user, assignee], people: [alice, _billy]] = create_people_and_lab_results()
      {:ok, index_live, _} = live(conn, "/people")

      index_live
      |> table_contents()
      |> assert_eq([
        ["", "Name", "ID", "Latest test result", "Assignee"],
        ["", "Billy Testuser", "billy-id", "negative, 3 days ago", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", ""]
      ])

      assert_select_dropdown_options(view: index_live, data_role: "users", expected: ["", "Unassigned", "assignee", "user"])

      assert_unchecked(index_live, alice.tid)
      index_live |> element("[data-role=#{alice.tid}]") |> render_click(%{"person-id" => alice.id, "value" => "on"})
      assert_checked(index_live, alice.tid)

      index_live |> element("#assignment-form") |> render_change(%{"user" => assignee.id})

      index_live
      |> table_contents()
      |> assert_eq([
        ["", "Name", "ID", "Latest test result", "Assignee"],
        ["", "Billy Testuser", "billy-id", "negative, 3 days ago", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", "assignee"]
      ])

      assert_unchecked(index_live, alice.tid)
    end

    test "users can be unassigned from people", %{conn: conn} do
      [users: [user, assignee], people: [alice, billy]] = create_people_and_lab_results()
      Cases.assign_user_to_people(user_id: assignee.id, people_ids: [alice.id, billy.id], originator: user)

      {:ok, index_live, _} = live(conn, "/people")

      index_live
      |> table_contents(columns: ["Name", "Assignee"])
      |> assert_eq([
        ["Name", "Assignee"],
        ["Billy Testuser", "assignee"],
        ["Alice Testuser", "assignee"]
      ])

      index_live |> element("[data-role=#{alice.tid}]") |> render_click(%{"person-id" => alice.id, "value" => "on"})
      index_live |> element("[data-role=#{billy.tid}]") |> render_click(%{"person-id" => billy.id, "value" => "on"})

      index_live |> element("#assignment-form") |> render_change(%{"user" => "-unassigned-"})
      assert_unchecked(index_live, alice.tid)
      assert_unchecked(index_live, billy.tid)

      Cases.get_people([alice.id, billy.id])
      |> Cases.preload_assigned_to()
      |> Euclid.Extra.Enum.pluck(:assigned_to)
      |> assert_eq([nil, nil])
    end

    test "shows assignee update from different client", %{conn: conn} do
      [users: [_user, assignee], people: [alice, _billy]] = create_people_and_lab_results()
      {:ok, index_live, _} = live(conn, "/people")

      index_live
      |> table_contents()
      |> assert_eq([
        ["", "Name", "ID", "Latest test result", "Assignee"],
        ["", "Billy Testuser", "billy-id", "negative, 3 days ago", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", ""]
      ])

      updated_people = [%{alice | assigned_to: assignee}]
      Cases.broadcast_people(updated_people)

      index_live
      |> table_contents()
      |> assert_eq([
        ["", "Name", "ID", "Latest test result", "Assignee"],
        ["", "Billy Testuser", "billy-id", "negative, 3 days ago", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", "assignee"]
      ])
    end

    test "shows people and their lab tests", %{conn: conn} do
      create_people_and_lab_results()

      {:ok, index_live, _html} = live(conn, "/people")

      index_live
      |> table_contents()
      |> assert_eq([
        ["", "Name", "ID", "Latest test result", "Assignee"],
        ["", "Billy Testuser", "billy-id", "negative, 3 days ago", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", ""]
      ])
    end

    test "shows a reload message after broadcasting with a new list of people", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, "/people")

      # start off with no people
      assert_role_text(index_live, "reload-message", "")

      index_live
      |> table_contents()
      |> assert_eq([
        ["", "Name", "ID", "Latest test result", "Assignee"]
      ])

      # import 2 people
      [users: _, people: people] = create_people_and_lab_results()

      Cases.broadcast_people(people)

      # show a button to make the people visible
      assert_role_text(index_live, "reload-message", "Show 2 new people")

      index_live
      |> table_contents()
      |> assert_eq([
        ["", "Name", "ID", "Latest test result", "Assignee"]
      ])

      # show the new people after the button is clicked
      render_click(index_live, "reload-people")
      assert_role_text(index_live, "reload-message", "")

      index_live
      |> table_contents()
      |> assert_eq([
        ["", "Name", "ID", "Latest test result", "Assignee"],
        ["", "Billy Testuser", "billy-id", "negative, 3 days ago", ""],
        ["", "Alice Testuser", "", "positive, 1 day ago", ""]
      ])

      # refresh the people
      Cases.broadcast_people(people)
      assert_role_text(index_live, "reload-message", "")
    end
  end

  describe "save button" do
    test "it is disabled by default", %{conn: conn} do
      create_people_and_lab_results()
      {:ok, index_live, _} = live(conn, "/people")
      assert_disabled(index_live, "users")
    end

    test "it is enabled after selecting a person", %{conn: conn} do
      [users: _users, people: [alice, _billy]] = create_people_and_lab_results()
      {:ok, index_live, _} = live(conn, "/people")
      assert_disabled(index_live, "users")
      index_live |> element("[data-role=#{alice.tid}]") |> render_click(%{"person-id" => alice.id, "value" => "on"})
      assert_enabled(index_live, "users")
    end
  end

  describe "full_name" do
    test "renders first and last name",
      do: assert(PeopleLive.full_name(%{first_name: "First", last_name: "Last"}) == "First Last")

    test "when there's just a first name",
      do: assert(PeopleLive.full_name(%{first_name: "First", last_name: nil}) == "First")

    test "when there's just a last name",
      do: assert(PeopleLive.full_name(%{first_name: nil, last_name: "Last"}) == "Last")

    test "when first name is blank",
      do: assert(PeopleLive.full_name(%{first_name: "", last_name: "Last"}) == "Last")
  end

  describe "latest_result" do
    setup do
      person = Test.Fixtures.user_attrs("user") |> Accounts.create_user!() |> Test.Fixtures.person_attrs("person") |> Cases.create_person!()

      [person: person]
    end

    test "when the person has no lab results", %{person: person} do
      assert PeopleLive.latest_result(person) == ""
    end

    test "when there is a result and a sample date", %{person: person} do
      Test.Fixtures.lab_result_attrs(person, "lab-result", ~D[2020-01-01], result: "positive") |> Cases.create_lab_result!()
      assert PeopleLive.latest_result(person) =~ ~r|positive, \d+ days ago|
    end
  end
end
