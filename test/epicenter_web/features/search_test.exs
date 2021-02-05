defmodule EpicenterWeb.Features.SearchTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Test
  alias Epicenter.Cases
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user
  @admin Test.Fixtures.admin()

  defp create_person(tid, demographic_attrs, person_attrs) do
    Test.Fixtures.person_attrs(@admin, tid, person_attrs) |> Test.Fixtures.add_demographic_attrs(demographic_attrs) |> Cases.create_person!()
  end

  test "user can perform a search", %{conn: conn} do
    conn
    |> Pages.People.visit()
    |> Pages.Navigation.assert_has_search_field()
    |> Pages.submit_live("[data-role=app-search] form", %{search: %{"term" => "anything"}})
    |> Pages.Search.assert_search_term_in_search_box("anything")
  end

  test "closing the search results", %{conn: conn} do
    conn
    |> Pages.People.visit()
    |> Pages.submit_live("[data-role=app-search] form", %{search: %{"term" => "id-that-does-not-exist"}})
    |> Pages.Search.close_search_results()
    |> Pages.People.assert_here()
  end

  describe "searching by ODRS id" do
    test "search for known person displays person page", %{conn: conn, user: user} do
      external_id = "10004"
      {:ok, person} = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person()
      {:ok, _} = Test.Fixtures.demographic_attrs(user, person, "first", %{external_id: external_id}) |> Cases.create_demographic()

      conn
      |> Pages.People.visit()
      |> Pages.submit_and_follow_redirect(conn, "[data-role=app-search] form", %{search: %{"term" => external_id}})
      |> Pages.Profile.assert_here(person)
    end

    test "searching for an existing person with extraneous whitespace", %{conn: conn, user: user} do
      external_id = "10004"
      whitespaced_external_id = "\t10004  "
      {:ok, person} = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person()

      {:ok, _} =
        Test.Fixtures.demographic_attrs(user, person, "first", %{external_id: external_id})
        |> Cases.create_demographic()

      conn
      |> Pages.People.visit()
      |> Pages.submit_and_follow_redirect(conn, "[data-role=app-search] form", %{search: %{"term" => whitespaced_external_id}})
      |> Pages.Profile.assert_here(person)
    end

    test "search for unknown person displays no results page", %{conn: conn, user: user} do
      external_id = "10004"
      {:ok, person} = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person()
      {:ok, _} = Test.Fixtures.demographic_attrs(user, person, "first", %{external_id: external_id}) |> Cases.create_demographic()

      conn
      |> Pages.People.visit()
      |> Pages.submit_live("[data-role=app-search] form", %{search: %{"term" => "id-that-does-not-exist"}})
      |> Pages.Search.assert_no_results("id-that-does-not-exist")
    end
  end

  describe "when there are multiple results" do
    test "it shows the results", %{conn: conn} do
      create_person("person1", %{first_name: "first"}, %{})
      create_person("person2", %{first_name: "first"}, %{})

      conn
      |> Pages.People.visit()
      |> Pages.submit_live("[data-role=app-search] form", %{search: %{"term" => "first"}})
      |> Pages.Search.assert_results([])
    end
  end
end
