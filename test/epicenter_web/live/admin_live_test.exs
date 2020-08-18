defmodule EpicenterWeb.AdminLiveTest do
  use EpicenterWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/admin")
    assert disconnected_html =~ "Admin"
    assert render(page_live) =~ "Admin"
  end
end
