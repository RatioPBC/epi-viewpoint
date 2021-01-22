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
      |> Cases.create_person!()

    person2 =
      Test.Fixtures.person_attrs(user, "alicia")
      |> Test.Fixtures.add_demographic_attrs(%{external_id: "111222"})
      |> Cases.create_person!()

    [user: user, person1: person1, person2: person2]
  end

  test "disconnected and connected render", %{conn: conn, person1: person1, person2: person2} do
    {:ok, page_live, disconnected_html} = live(conn, "/resolve-conflicts?person_ids=#{person1.id},#{person2.id}")

    assert_has_role(disconnected_html, "resolve-conflicts-page")
    assert_has_role(page_live, "resolve-conflicts-page")
  end

  test "showing the merge conflicts", %{conn: conn, person1: person1, person2: person2} do
    Pages.ResolveConflicts.visit(conn, [person1.id, person2.id])
    |> Pages.ResolveConflicts.assert_unique_values_present("first_name", ["Alice", "Alicia"])
  end

  # TODO what if 0 or 1 person ids are sent to the page
end
