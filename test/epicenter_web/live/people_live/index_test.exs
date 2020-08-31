defmodule EpicenterWeb.PeopleLive.IndexTest do
  use EpicenterWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Import
  alias Epicenter.Test

  defp people(page_live),
    do: page_live |> render() |> Test.Html.parse_doc() |> Test.Html.all("[data-role=person]", as: :tids)

  defp table_contents(page_live),
    do: page_live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(role: "people")

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/people")

    assert_has_role(disconnected_html, "people-page")
    assert_has_role(page_live, "people-page")
  end

  test "shows people and person count", %{conn: conn} do
    user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
    Test.Fixtures.person_attrs(user, "alice", "06-01-2000") |> Cases.create_person!()
    Test.Fixtures.person_attrs(user, "billy", "06-01-2000") |> Cases.create_person!()

    {:ok, page_live, _html} = live(conn, "/people")

    page_live
    |> table_contents()
    |> assert_eq([
      ["Name", "DOB", "Latest lab status", "Latest lab date"],
      ["Alice Aliceblat", "2000-06-01", "", ""],
      ["Billy Billyblat", "2000-06-01", "", ""]
    ])
  end

  test "shows a reload message after an import", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/people")

    # start off with no people
    assert_role_text(page_live, "reload-message", "")

    page_live
    |> table_contents()
    |> assert_eq([
      ["Name", "DOB", "Latest lab status", "Latest lab date"]
    ])

    # import 2 people
    user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
    Test.Fixtures.person_attrs(user, "alice", "06-01-2000") |> Cases.create_person!()
    Test.Fixtures.person_attrs(user, "billy", "06-01-2000") |> Cases.create_person!()

    import_info = %Import.ImportInfo{
      imported_person_count: 2,
      imported_lab_result_count: 0,
      total_person_count: 2,
      total_lab_result_count: 0
    }

    Cases.broadcast({:import, import_info})

    # show a button to make the people visible
    assert_role_text(page_live, "reload-message", "Show 2 new people")
    page_live |> people() |> assert_eq(~w{})

    # show the new people after the button is clicked
    render_click(page_live, "refresh-people")
    assert_role_text(page_live, "reload-message", "")

    page_live
    |> table_contents()
    |> assert_eq([
      ["Name", "DOB", "Latest lab status", "Latest lab date"],
      ["Alice Aliceblat", "2000-06-01", "", ""],
      ["Billy Billyblat", "2000-06-01", "", ""]
    ])
  end
end
