defmodule EpicenterWeb.ResolveConflictsLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    #    person =
    #      Test.Fixtures.person_attrs(user, "alice")
    #      |> Test.Fixtures.add_demographic_attrs(%{external_id: "987650"})
    #      |> Cases.create_person!()

    [user: user]
  end

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/resolve-conflicts")

    assert_has_role(disconnected_html, "resolve-conflicts-page")
    assert_has_role(page_live, "resolve-conflicts-page")
  end

  test "showing the page", %{conn: conn} do
    Pages.ResolveConflicts.visit(conn)
    |> Pages.ResolveConflicts.assert_here()
  end
end
