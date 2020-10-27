defmodule EpicenterWeb.CaseInvestigationStartLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Cases
  alias Epicenter.Test

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    [person: person, user: user]
  end

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}/case_investigations/todo/start")

    assert_has_role(disconnected_html, "case-investigation-start-page")
    assert_has_role(page_live, "case-investigation-start-page")
  end
end
