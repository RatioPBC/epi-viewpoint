defmodule EpicenterWeb.Test.Pages.Login do
  alias EpicenterWeb.Test.Pages
  alias Plug.Conn

  def log_in(%Conn{} = conn, email, password),
    do: Pages.submit_form(conn, :post, "login-form", "user", %{"email" => email, "password" => password})
end
