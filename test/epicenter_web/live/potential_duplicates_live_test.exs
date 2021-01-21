defmodule EpicenterWeb.PotentialDuplicatesLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Test.Fixtures.add_demographic_attrs(%{external_id: "987650"})
      |> Cases.create_person!()

    [person: person, user: user]
  end

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}/potential-duplicates")

    assert_has_role(disconnected_html, "potential-duplicates-page")
    assert_has_role(page_live, "potential-duplicates-page")
  end

  test "showing the page", %{conn: conn, person: person} do
    Pages.PotentialDuplicates.visit(conn, person)
    |> Pages.PotentialDuplicates.assert_here(person)
  end
end
