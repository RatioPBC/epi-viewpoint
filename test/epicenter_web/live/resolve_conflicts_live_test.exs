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

  test "showing the merge conflicts", %{conn: conn, person1: person1, person2: person2} do
    Pages.ResolveConflicts.visit(conn, person1.id, [person2.id])
    |> Pages.ResolveConflicts.assert_unique_values_present("first_name", ["Alice", "Alicia"])
  end

  test "when there are no conflicts, we do not render a form line", %{conn: conn, person1: person1, person2: person2} do
    Pages.ResolveConflicts.visit(conn, person1.id, [person2.id])
    |> Pages.ResolveConflicts.assert_no_conflicts_for_field("dob")
  end

  test "save button is disabled until all conflicts are resolved", %{conn: conn, person1: person1, person2: person2} do
    Pages.ResolveConflicts.visit(conn, person1.id, [person2.id])
    |> Pages.ResolveConflicts.assert_save_button_enabled(false)
    |> Pages.ResolveConflicts.click_first_name("Alicia")
    |> Pages.ResolveConflicts.assert_save_button_enabled(true)
  end

  # TODO what if 0 or 1 person ids are sent to the page
end
