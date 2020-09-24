defmodule EpicenterWeb.Test.Pages do
  @endpoint EpicenterWeb.Endpoint

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  def visit(%Plug.Conn{} = conn, path) do
    {:ok, view, _html} = live(conn, path)
    view
  end
end
