defmodule EpicenterWeb.Features.SearchTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.ConnTest

  alias Epicenter.Test
  alias Epicenter.Cases
  alias EpicenterWeb.Test.Pages
  alias EpicenterWeb.Test.Search

  setup :register_and_log_in_user

  test "users see the seach field in the nav bar", %{conn: conn} do
    conn
    |> get("/people")
    |> Pages.Navigation.assert_has_search_field()
  end

  describe "searching by ODRS id" do
    test "search for known person displays person page", %{conn: conn, user: user} do
      external_id = "10004"
      {:ok, person} = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person()
      {:ok, _} = Test.Fixtures.demographic_attrs(user, person, "first", %{external_id: external_id}) |> Cases.create_demographic()

      conn
      |> Pages.People.visit()
      |> Pages.submit_and_follow_redirect(conn, "[data-role=app-search] form", %{search_form: %{"term" => external_id}})
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
      |> Pages.submit_and_follow_redirect(conn, "[data-role=app-search] form", %{search_form: %{"term" => whitespaced_external_id}})
      |> Pages.Profile.assert_here(person)
    end

    test "search for unknown person displays no results page", %{conn: conn, user: user} do
      external_id = "10004"
      {:ok, person} = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person()
      {:ok, _} = Test.Fixtures.demographic_attrs(user, person, "first", %{external_id: external_id}) |> Cases.create_demographic()

      conn
      |> Pages.People.visit()
      |> Pages.submit_and_follow_redirect(conn, "[data-role=app-search] form", %{search_form: %{"term" => "id-that-does-not-exist"}})
      |> Search.assert_no_results()
    end
  end
end
