defmodule EpicenterWeb.Test.Pages.Mfa do
  alias Epicenter.Test.TOTPStub
  alias EpicenterWeb.Test.Pages
  alias Plug.Conn

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("multifactor-auth")

  def submit_passcode(%Conn{} = conn),
    do: Pages.submit_form(conn, :post, "multifactor-auth-form", "user", %{"passcode" => TOTPStub.valid_passcode()})
end
