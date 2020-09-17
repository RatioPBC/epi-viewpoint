defmodule EpicenterWeb.Features.AssignmentsTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test

  defp table_contents(live, opts),
    do: live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "people"))

  test "people can be assigned to users on index and show page, with cross-client updating", %{conn: conn} do
    assignee = Test.Fixtures.user_attrs("assignee") |> Accounts.create_user!()
    Test.Fixtures.user_attrs("nonassignee") |> Accounts.create_user!()

    alice = Test.Fixtures.person_attrs(assignee, "alice") |> Cases.create_person!()
    billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()

    {:ok, index_page, _html} = live(conn, "/people")
    {:ok, show_page, _html} = live(conn, "/people/#{alice.id}")

    index_page
    |> table_contents(columns: ["Name", "Assignee"])
    |> assert_eq([
      ["Name", "Assignee"],
      ["Alice Testuser", ""],
      ["Billy Testuser", ""]
    ])

    # choose "assignee" via show page
    assert_select_dropdown_options(view: show_page, data_role: "users", expected: ["Unassigned", "assignee", "nonassignee"])
    show_page |> element("#assignment-form") |> render_change(%{"user" => assignee.id})
    assert_selected_dropdown_option(view: show_page, data_role: "users", expected: ["assignee"])
    assert Cases.get_person(alice.id) |> Cases.preload_assigned_to() |> Map.get(:assigned_to) |> Map.get(:tid) == "assignee"

    # "assignee" shows up on index page
    index_page
    |> table_contents(columns: ["Name", "Assignee"])
    |> assert_eq([
      ["Name", "Assignee"],
      ["Alice Testuser", "assignee"],
      ["Billy Testuser", ""]
    ])

    # unassign "assignee" via show page
    show_page |> element("#assignment-form") |> render_change(%{"user" => "-unassigned-"})
    assert_selected_dropdown_option(view: show_page, data_role: "users", expected: ["Unassigned"])
    assert Cases.get_person(alice.id) |> Cases.preload_assigned_to() |> Map.get(:assigned_to) == nil

    # "assignee" disappears from index page
    index_page
    |> table_contents(columns: ["Name", "Assignee"])
    |> assert_eq([
      ["Name", "Assignee"],
      ["Alice Testuser", ""],
      ["Billy Testuser", ""]
    ])

    # choose "assignee" via index page
    index_page |> element("[data-role=#{alice.tid}]") |> render_click(%{"person-id" => alice.id, "value" => "on"})
    index_page |> element("[data-role=#{billy.tid}]") |> render_click(%{"person-id" => billy.id, "value" => "on"})
    index_page |> element("#assignment-form") |> render_change(%{"user" => assignee.id})

    assert_selected_dropdown_option(view: show_page, data_role: "users", expected: ["assignee"])
  end

  @tag :skip
  test "renders changes when updating existing person and prompts to refresh when importing new person"
end
