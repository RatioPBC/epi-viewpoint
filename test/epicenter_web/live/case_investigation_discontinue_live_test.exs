defmodule EpicenterWeb.CaseInvestigationDiscontinueLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    [person: person, user: user]
  end

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}/case_investigations/todo/discontinue")

    assert_has_role(disconnected_html, "case-investigation-discontinue-page")
    assert_has_role(page_live, "case-investigation-discontinue-page")
  end

  test "has a reason select radio", %{conn: conn, person: person} do
    Pages.CaseInvestigationDiscontinue.visit(conn, person)
    |> Pages.CaseInvestigationDiscontinue.assert_here()
    |> Pages.CaseInvestigationDiscontinue.assert_reason_selections(%{
      " Unable to reach" => false,
      " Transferred to another jurisdiction" => false,
      " Deceased" => false,
      " Other" => false
    })
  end
end
