defmodule EpiViewpointWeb.Test.Pages.UserLogins do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias EpiViewpoint.Accounts.User
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("user-logins")
  end

  def assert_page_header(%View{} = view, expected_text) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find!("[data-role=title]")
    |> Test.Html.text()
    |> assert_eq(expected_text)

    view
  end

  def visit(%Plug.Conn{} = conn, %User{id: user_id}) do
    conn |> Pages.visit("/admin/user/#{user_id}/logins")
  end

  def assert_table_contents(%View{} = view, expected_table_content, opts \\ []) do
    assert table_contents(view, opts) == expected_table_content
    view
  end

  defp table_contents(index_live, opts),
    do: index_live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "logins-table"))
end
