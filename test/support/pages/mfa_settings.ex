defmodule EpicenterWeb.Test.Pages.MfaSettings do
  alias EpicenterWeb.Test.Pages
  alias Plug.Conn

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("mfa-settings")
end
