defmodule EpicenterWeb.PeopleLive.EditTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/1/edit")

    assert_has_role(disconnected_html, "person-edit-page")
    assert_has_role(page_live, "person-edit-page")
  end
end
