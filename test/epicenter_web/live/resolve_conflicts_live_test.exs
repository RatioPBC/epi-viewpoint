defmodule EpicenterWeb.ResolveConflictsLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person1 =
      Test.Fixtures.person_attrs(user, "alice")
      |> Test.Fixtures.add_demographic_attrs(%{external_id: "987650"})
      |> Test.Fixtures.add_demographic_attrs(%{dob: ~D[1980-01-01]})
      |> Cases.create_person!()

    person2 =
      Test.Fixtures.person_attrs(user, "alicia")
      |> Test.Fixtures.add_demographic_attrs(%{external_id: "111222"})
      |> Test.Fixtures.add_demographic_attrs(%{dob: ~D[1980-01-01]})
      |> Cases.create_person!()

    [user: user, person1: person1, person2: person2]
  end

  test "disconnected and connected render", %{conn: conn, person1: person1, person2: person2} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person1.id}/resolve-conflicts?duplicate_person_ids=#{person2.id}")

    assert_has_role(disconnected_html, "resolve-conflicts-page")
    assert_has_role(page_live, "resolve-conflicts-page")
  end

  test "shows merge conflict line for conflicting fields", %{conn: conn, person1: person1, person2: person2} do
    Pages.ResolveConflicts.visit(conn, person1.id, [person2.id])
    |> Pages.ResolveConflicts.assert_unique_values_present("first_name", ["Alice", "Alicia"])
    |> Pages.ResolveConflicts.assert_message("These fields differ between the merged records. Choose the correct information for each.")
  end

  test "doesn't show merge conflict line for non-conflicting fields", %{conn: conn, person1: person1, person2: person2} do
    Pages.ResolveConflicts.visit(conn, person1.id, [person2.id])
    |> Pages.ResolveConflicts.assert_no_conflicts_for_field("dob")
  end

  test "when there are no conflicting fields, no form lines are shown and the message and button are different", %{
    user: user,
    conn: conn,
    person1: person1
  } do
    non_conflicting_person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Test.Fixtures.add_demographic_attrs(%{external_id: "111222"})
      |> Test.Fixtures.add_demographic_attrs(%{dob: ~D[1980-01-01]})
      |> Cases.create_person!()

    Pages.ResolveConflicts.visit(conn, person1.id, [non_conflicting_person.id])
    |> Pages.ResolveConflicts.assert_no_conflicts()
    |> Pages.ResolveConflicts.assert_message("No conflicts found.")
  end

  test "save button is disabled until all conflicts are resolved", %{conn: conn, person1: person1, person2: person2} do
    Pages.ResolveConflicts.visit(conn, person1.id, [person2.id])
    |> Pages.ResolveConflicts.assert_merge_button_enabled(false)
    |> Pages.ResolveConflicts.click_first_name("Alicia")
    |> Pages.ResolveConflicts.assert_merge_button_enabled(true)
  end

  # TODO what if 0 or 1 person ids are sent to the page
end
