defmodule EpiViewpointWeb.Test.Pages.User do
  import Phoenix.LiveViewTest

  alias EpiViewpointWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn) do
    conn |> Pages.visit("/admin/user")
  end

  def visit(%Plug.Conn{} = conn, %EpiViewpoint.Accounts.User{} = user) do
    conn |> Pages.visit("/admin/user/#{user.id}")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("user")
  end

  def change_form(%View{} = view, attrs) do
    view |> element("#user-form") |> render_change(attrs)

    view
  end
end
