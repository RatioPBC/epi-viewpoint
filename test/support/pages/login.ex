defmodule EpiViewpointWeb.Test.Pages.Login do
  alias EpiViewpointWeb.Test.Pages
  alias Plug.Conn

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("login")

  def log_in(%Conn{} = conn, email, password),
    do: Pages.submit_form(conn, :post, "login-form", "user", %{"email" => email, "password" => password})
end
