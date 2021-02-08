defmodule EpicenterWeb.Features.SearchTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Test
  alias Epicenter.Cases
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user
  @admin Test.Fixtures.admin()

  defp create_person(tid, demographic_attrs, person_attrs) do
    Test.Fixtures.person_attrs(@admin, tid, person_attrs)
    |> Test.Fixtures.add_demographic_attrs(demographic_attrs)
    |> Cases.create_person!()
  end

  test "user can perform a search and then close the results", %{conn: conn} do
    create_person("alice", %{first_name: "alice"}, %{})
    create_person("billy", %{first_name: "billy"}, %{})

    conn
    |> Pages.People.visit()
    |> Pages.Navigation.assert_has_search_field()
    |> Pages.Search.search("testuser")
    |> Pages.Search.assert_search_term_in_search_box("testuser")
    |> Pages.Search.assert_results(~w[alice billy])
    |> Pages.Search.close_search_results()
    |> Pages.Search.assert_results_visible(false)
  end

  test "a message is shown when there are no search results", %{conn: conn} do
    conn
    |> Pages.People.visit()
    |> Pages.Search.search("id-that-does-not-exist")
    |> Pages.Search.assert_results([])
  end

  # skipped for now since we're not sure we'll be handling IDs differently than other things
  describe "searching by ODRS id" do
    @tag :skip
    test "search for known person displays person page", %{conn: conn, user: user} do
      external_id = "10004"
      {:ok, person} = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person()
      {:ok, _} = Test.Fixtures.demographic_attrs(user, person, "first", %{external_id: external_id}) |> Cases.create_demographic()

      conn
      |> Pages.People.visit()
      |> Pages.Search.search(external_id)
      |> Pages.Profile.assert_here(person)
    end

    @tag :skip
    test "searching for an existing person with extraneous whitespace", %{conn: conn, user: user} do
      external_id = "10004"
      whitespaced_external_id = "\t10004  "
      {:ok, person} = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person()

      {:ok, _} =
        Test.Fixtures.demographic_attrs(user, person, "first", %{external_id: external_id})
        |> Cases.create_demographic()

      conn
      |> Pages.People.visit()
      |> Pages.Search.search(whitespaced_external_id)
      |> Pages.Profile.assert_here(person)
    end

    @tag :skip
    test "search for unknown person displays no results page", %{conn: conn, user: user} do
      external_id = "10004"
      {:ok, person} = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person()
      {:ok, _} = Test.Fixtures.demographic_attrs(user, person, "first", %{external_id: external_id}) |> Cases.create_demographic()

      conn
      |> Pages.People.visit()
      |> Pages.Search.search("id-that-does-not-exist")
      |> Pages.Search.assert_no_results("id-that-does-not-exist")
    end
  end
end
