defmodule EpicenterWeb.PeopleLive.IndexTest do
  use EpicenterWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Import
  alias Epicenter.Extra
  alias Epicenter.Test
  alias EpicenterWeb.PeopleLive.Index

  describe "rendering" do
    defp table_contents(page_live),
      do: page_live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(role: "people")

    test "disconnected and connected render", %{conn: conn} do
      {:ok, page_live, disconnected_html} = live(conn, "/people")

      assert_has_role(disconnected_html, "people-page")
      assert_has_role(page_live, "people-page")
    end

    test "shows people and their lab tests", %{conn: conn} do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()

      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, "alice-result-1", Extra.Date.days_ago(1), result: "positive") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, "alice-result-2", Extra.Date.days_ago(2), result: "negative") |> Cases.create_lab_result!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(billy, "billy-result-1", Extra.Date.days_ago(3), result: "negative") |> Cases.create_lab_result!()

      {:ok, page_live, _html} = live(conn, "/people")

      page_live
      |> table_contents()
      |> assert_eq([
        ["Name", "DOB", "Latest test result"],
        ["Alice Testuser", "2000-01-01", "positive, 1 day ago"],
        ["Billy Testuser", "2000-01-01", "negative, 3 days ago"]
      ])
    end

    test "shows a reload message after an import", %{conn: conn} do
      {:ok, page_live, _html} = live(conn, "/people")

      # start off with no people
      assert_role_text(page_live, "reload-message", "")

      page_live
      |> table_contents()
      |> assert_eq([
        ["Name", "DOB", "Latest test result"]
      ])

      # import 2 people
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()

      import_info = %Import.ImportInfo{
        imported_person_count: 2,
        imported_lab_result_count: 0,
        total_person_count: 2,
        total_lab_result_count: 0
      }

      Cases.broadcast({:import, import_info})

      # show a button to make the people visible
      assert_role_text(page_live, "reload-message", "Show 2 new people")

      page_live
      |> table_contents()
      |> assert_eq([
        ["Name", "DOB", "Latest test result"]
      ])

      # show the new people after the button is clicked
      render_click(page_live, "refresh-people")
      assert_role_text(page_live, "reload-message", "")

      page_live
      |> table_contents()
      |> assert_eq([
        ["Name", "DOB", "Latest test result"],
        ["Alice Testuser", "2000-01-01", ""],
        ["Billy Testuser", "2000-01-01", ""]
      ])
    end
  end

  describe "full_name" do
    test "renders first and last name",
      do: assert(Index.full_name(%{first_name: "First", last_name: "Last"}) == "First Last")

    test "when there's just a first name",
      do: assert(Index.full_name(%{first_name: "First", last_name: nil}) == "First")

    test "when there's just a last name",
      do: assert(Index.full_name(%{first_name: nil, last_name: "Last"}) == "Last")

    test "when first name is blank",
      do: assert(Index.full_name(%{first_name: "", last_name: "Last"}) == "Last")
  end

  describe "latest_result" do
    setup do
      person = Test.Fixtures.user_attrs("user") |> Accounts.create_user!() |> Test.Fixtures.person_attrs("person") |> Cases.create_person!()

      [person: person]
    end

    test "when the person has no lab results", %{person: person} do
      assert Index.latest_result(person) == ""
    end

    test "when there is a result and a sample date", %{person: person} do
      Test.Fixtures.lab_result_attrs(person, "lab-result", ~D[2020-01-01], result: "positive") |> Cases.create_lab_result!()
      assert Index.latest_result(person) =~ ~r|positive, \d+ days ago|
    end
  end
end
