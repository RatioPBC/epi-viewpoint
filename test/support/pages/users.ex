defmodule EpicenterWeb.Test.Pages.Users do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn) do
    conn |> Pages.visit("/admin/users")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("users")
  end

  def assert_users(%View{} = view, expected_users) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Table.table_contents(role: "users-table")
    |> assert_eq(expected_users, :simple)

    view
  end
end
