defmodule EpicenterWeb.Test.Pages do
  @endpoint EpicenterWeb.Endpoint

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Phoenix.LiveViewTest.View

  def follow_liveview_redirect(x, conn) do
    follow_redirect(x, conn)
  end

  def parse(%View{} = view) do
    view |> render() |> Test.Html.parse()
  end

  def visit(%Plug.Conn{} = conn, path) do
    {:ok, view, _html} = live(conn, path)
    view
  end
end
