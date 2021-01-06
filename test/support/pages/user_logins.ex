defmodule EpicenterWeb.Test.Pages.UserLogins do
  import Euclid.Test.Extra.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
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
end
