defmodule EpicenterWeb.PeopleLiveTest do
  use EpicenterWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Epicenter.Cases
  alias Epicenter.Cases.Import
  alias Epicenter.Test

  defp cases(page_live),
    do: page_live |> render() |> Test.Html.parse_doc() |> Test.Html.all("[data-role=case]", as: :tids)

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/people")

    assert_has_role(disconnected_html, "cases-page")
    assert_has_role(page_live, "cases-page")
  end

  test "shows cases and case count", %{conn: conn} do
    Test.Fixtures.person_attrs("alice", "06-01-2000") |> Cases.create_person!()
    Test.Fixtures.person_attrs("billy", "06-01-2000") |> Cases.create_person!()

    {:ok, page_live, _html} = live(conn, "/people")

    assert_role_text(page_live, "case-count", "2 cases")
    page_live |> cases() |> assert_eq(~w{alice billy})
  end

  test "shows a reload message after an import", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/people")

    # start off with no cases
    assert_role_text(page_live, "case-count", "0 cases")
    assert_role_text(page_live, "reload-message", "")
    page_live |> cases() |> assert_eq(~w{})

    # import 2 cases
    Test.Fixtures.person_attrs("alice", "06-01-2000") |> Cases.create_person!()
    Test.Fixtures.person_attrs("billy", "06-01-2000") |> Cases.create_person!()

    import_info = %Import.ImportInfo{
      imported_person_count: 2,
      imported_lab_result_count: 0,
      total_person_count: 2,
      total_lab_result_count: 0
    }

    Cases.broadcast({:import, import_info})

    # show a button to make the cases visible
    assert_role_text(page_live, "case-count", "0 cases")
    assert_role_text(page_live, "reload-message", "Show 2 new cases")
    page_live |> cases() |> assert_eq(~w{})

    # show the new cases after the button is clicked
    render_click(page_live, "refresh-cases")
    assert_role_text(page_live, "case-count", "2 cases")
    assert_role_text(page_live, "reload-message", "")
    page_live |> cases() |> assert_eq(~w{alice billy})
  end
end
