defmodule EpicenterWeb.PageLiveTest do
  use EpicenterWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/page")
    assert disconnected_html =~ "No data here yet"
    assert render(page_live) =~ "No data here yet"
  end
end
