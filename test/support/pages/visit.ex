defmodule EpicenterWeb.Test.Pages.Visit do
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn),
    do: conn |> Pages.visit("/visit")

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("visit")

  def submit_visit(view, _occurred_on),
    do: view
end
