defmodule EpicenterWeb.Test.Pages.ImportLive do
  import Phoenix.LiveViewTest

  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn),
    do: conn |> Pages.visit("/import/start", :follow_redirect)

  def upload_button_visible?(%View{} = view),
    do: view |> element("[data-role=upload-labs]") |> has_element?()
end
