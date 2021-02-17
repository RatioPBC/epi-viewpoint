defmodule EpicenterWeb.Test.Pages.Place do
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn),
    do: conn |> Pages.visit("/place")

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("place")

  def submit_place(view, name: _place_name, type: _place_type),
    do: view
end
