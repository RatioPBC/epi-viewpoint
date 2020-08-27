defmodule EpicenterWeb.PeopleLive.EditTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test

  test "disconnected and connected render", %{conn: conn} do
    user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
    %Cases.Person{id: id} = Test.Fixtures.person_attrs(user, "alice", "06-01-2000") |> Cases.create_person!()

    {:ok, page_live, disconnected_html} = live(conn, "/people/#{id}/edit")

    assert_has_role(disconnected_html, "person-edit-page")
    assert_has_role(page_live, "person-edit-page")
  end

  test "editing person identifying information", %{conn: conn} do
    user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
    person = Test.Fixtures.person_attrs(user, "alice", "06-01-2000") |> Cases.create_person!()

    {:ok, page_live, _html} = live(conn, "/people/#{person.id}/edit")

    params = %{"person" => %{"first_name" => "Aaron", "last_name" => "Aaronblat"}}
    {:ok, redirected_view, _} = page_live |> render_submit("save", params) |> follow_redirect(conn)

    assert_role_text(redirected_view, "first-name", "Aaron")
    assert_role_text(redirected_view, "last-name", "Aaronblat")
    assert_versioned(person, expected_count: 2)
  end
end