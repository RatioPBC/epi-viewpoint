defmodule EpicenterWeb.AdminLiveTest do
  use EpicenterWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Epicenter.Cases
  alias Epicenter.Test

  setup :register_and_log_in_user

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/admin")

    assert_has_role(disconnected_html, "admin-page")
    assert_has_role(page_live, "admin-page")
  end

  test "shows person count and lab result count before and after importing", %{conn: conn, user: user} do
    {:ok, page_live, _html} = live(conn, "/admin")

    assert_role_text(page_live, "person-count", "0")
    assert_role_text(page_live, "lab-result-count", "0")

    alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    Test.Fixtures.lab_result_attrs(alice, "lab1", ~D[2020-04-10]) |> Cases.create_lab_result!()

    Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
    Test.Fixtures.person_attrs(user, "cindy") |> Cases.create_person!()

    Cases.broadcast_people([alice])

    assert_role_text(page_live, "person-count", "3")
    assert_role_text(page_live, "lab-result-count", "1")
  end
end
