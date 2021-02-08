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

  test "user can perform a search and then close the results", %{conn: conn, user: user} do
    alice = create_person("alice", %{first_name: "Alice", dob: ~D[1990-12-01], sex_at_birth: "female"}, %{})
    billy = create_person("billy", %{first_name: "Billy", dob: ~D[1941-08-01], sex_at_birth: "male"}, %{})

    Test.Fixtures.phone_attrs(user, alice, "preferred", number: "111-111-1222") |> Cases.create_phone!()
    Test.Fixtures.phone_attrs(user, billy, "preferred", number: "111-111-1333") |> Cases.create_phone!()

    Test.Fixtures.address_attrs(user, alice, "alice-address", 1000, type: "home") |> Cases.create_address!()
    Test.Fixtures.address_attrs(user, billy, "billy-address", 1222, type: "home") |> Cases.create_address!()

    Test.Fixtures.lab_result_attrs(alice, @admin, "lab-result", ~D[2020-12-01]) |> Cases.create_lab_result!()

    conn
    |> Pages.People.visit()
    |> Pages.Navigation.assert_has_search_field()
    |> Pages.Search.search("testuser")
    |> Pages.Search.assert_search_term_in_search_box("testuser")
    |> Pages.Search.assert_results([
      ["Alice Testuser", "12/01/1990Female(111) 111-12221000 Test St, City, OH 00000", "Latest lab result on 12/01/2020"],
      ["Billy Testuser", "08/01/1941Male(111) 111-13331222 Test St, City, OH 00000", "No lab results"]
    ])
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
