defmodule EpiViewpointWeb.Test.Pages.ImportLive do
  import Phoenix.LiveViewTest

  alias EpiViewpointWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn),
    do: conn |> Pages.visit("/import/start")

  def upload_button_visible?(%View{} = view),
    do: view |> element("[data-role=upload-labs]") |> has_element?()
end
