defmodule EpicenterWeb.Test.Pages.ResetPassword do
  alias EpicenterWeb.Test.Pages
  alias Plug.Conn

  def visit(%Conn{} = conn, url),
    do: Pages.visit(conn, url |> URI.parse() |> Map.get(:path), :notlive)

  def assert_here(%Conn{} = conn),
    do: conn |> Pages.assert_on_page("reset-password")

  def change_password(%Conn{} = conn, password),
    do: Pages.submit_form(conn, :put, "reset-password-form", "user", %{"password" => password, "password_confirmation" => password})
end
