defmodule EpicenterWeb.Test.Pages.Contacts do
  alias EpicenterWeb.Test.Pages

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("contacts")

  def visit(%Plug.Conn{} = conn),
    do: conn |> Pages.visit("/contacts")
end
