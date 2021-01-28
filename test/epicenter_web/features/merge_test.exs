defmodule EpicenterWeb.Features.MergeTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  @admin Test.Fixtures.admin()

  test "user can review potential duplicates and merge records", %{conn: conn} do
    person = create_person("person", %{last_name: "Testuser", first_name: "Alice"})
    duplicate = create_person("duplicate", %{last_name: "Testuser", first_name: "Different"})

    Pages.Profile.visit(conn, person)
    |> Pages.Profile.click_view_potential_duplicates()
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.PotentialDuplicates.assert_here(person)
    |> Pages.PotentialDuplicates.set_selected_people([duplicate])
    |> Pages.PotentialDuplicates.submit_merge()
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ResolveConflicts.assert_here()
    |> Pages.ResolveConflicts.assert_first_names_present(["Alice", "Different"])
  end

  defp create_person(tid, attrs) do
    Test.Fixtures.person_attrs(@admin, tid, %{}) |> Test.Fixtures.add_demographic_attrs(attrs) |> Cases.create_person!()
  end
end
