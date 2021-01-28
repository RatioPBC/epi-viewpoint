defmodule EpicenterWeb.Features.MergeTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  @admin Test.Fixtures.admin()

  test "user can review potential duplicates and merge records", %{conn: conn} do
    person = create_person("person", %{last_name: "Testuser", first_name: "Alice"})
    duplicate1 = create_person("duplicate1", %{last_name: "Testuser", first_name: "Alice"})
    create_person("duplicate2", %{last_name: "Testuser", first_name: "Alice"})

    Pages.Profile.visit(conn, person)
    |> Pages.Profile.click_view_potential_duplicates()
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.PotentialDuplicates.assert_here(person)
    |> Pages.PotentialDuplicates.set_selected_people([duplicate1])
    |> Pages.PotentialDuplicates.submit_merge()
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ResolveConflicts.assert_here()
  end

  defp create_person(tid, attrs) do
    Test.Fixtures.person_attrs(@admin, tid, %{}) |> Test.Fixtures.add_demographic_attrs(attrs) |> Cases.create_person!()
  end
end
