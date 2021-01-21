defmodule EpicenterWeb.Test.Pages.ResolveConflicts do
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn) do
    conn |> Pages.visit("/resolve-conflicts")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("resolve-conflicts")
    view_or_conn_or_html
  end
end
