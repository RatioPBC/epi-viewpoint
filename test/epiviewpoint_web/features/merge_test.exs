defmodule EpiViewpointWeb.Features.MergeTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Cases
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

  setup :register_and_log_in_user

  @admin Test.Fixtures.admin()

  test "user can review potential duplicates and merge records", %{conn: conn} do
    person =
      create_person("person", %{
        last_name: "Testuser",
        first_name: "Alice",
        dob: ~D[2001-01-01],
        preferred_language: "English"
      })
      |> add_phone("111-111-1111")

    duplicate =
      create_person("duplicate", %{
        last_name: "Testuser",
        first_name: "Different",
        dob: ~D[2003-01-01],
        preferred_language: "Spanish"
      })
      |> add_phone("111-111-1111")

    Pages.Profile.visit(conn, person)
    |> Pages.Profile.click_view_potential_duplicates()
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.PotentialDuplicates.assert_here(person)
    |> Pages.PotentialDuplicates.set_selected_people([duplicate])
    |> Pages.PotentialDuplicates.submit_merge()
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ResolveConflicts.assert_here()
    |> Pages.ResolveConflicts.assert_first_names_present(["Alice", "Different"])
    |> Pages.submit_and_follow_redirect(conn, "#resolve-conflicts-form",
      resolve_conflicts_form: %{
        "first_name" => "Different",
        "dob" => "01/01/2003",
        "preferred_language" => "Spanish"
      }
    )
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.assert_full_name("Different Testuser")
    |> Pages.Profile.assert_date_of_birth("01/01/2003")
    |> Pages.Profile.assert_preferred_language("Spanish")
    |> Pages.Profile.refute_potential_duplicates()
  end

  test "user can merge records with no conflicting fields", %{conn: conn} do
    person =
      create_person("person", %{
        last_name: "Testuser",
        first_name: "Alice",
        dob: ~D[2001-01-01],
        preferred_language: "English"
      })
      |> add_phone("111-111-1111")

    duplicate =
      create_person("duplicate", %{
        last_name: "Testuser",
        first_name: "Alice",
        dob: ~D[2001-01-01],
        preferred_language: "English"
      })
      |> add_phone("111-111-1111")

    Pages.Profile.visit(conn, person)
    |> Pages.Profile.click_view_potential_duplicates()
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.PotentialDuplicates.assert_here(person)
    |> Pages.PotentialDuplicates.set_selected_people([duplicate])
    |> Pages.PotentialDuplicates.submit_merge()
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ResolveConflicts.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#resolve-conflicts-form", resolve_conflicts_form: %{})
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.assert_full_name("Alice Testuser")
  end

  defp create_person(tid, attrs) do
    Test.Fixtures.person_attrs(@admin, tid, %{}) |> Test.Fixtures.add_demographic_attrs(attrs) |> Cases.create_person!()
  end

  defp add_phone(person, number) do
    %Cases.Phone{} = Test.Fixtures.phone_attrs(@admin, person, person.tid, %{number: number}) |> Cases.create_phone!()
    person
  end
end
