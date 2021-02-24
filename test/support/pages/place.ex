defmodule EpicenterWeb.Test.Pages.Place do
  import Euclid.Test.Extra.Assertions

  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, case_investigation),
    do: conn |> Pages.visit("/case-investigations/#{case_investigation.id}/place")

  def assert_here(view_or_conn_or_html, case_investigation) do
    view_or_conn_or_html
    |> Pages.assert_on_page("place")
    |> Pages.parse()
    |> Test.Html.attr("#place-page", "data-tid")
    |> assert_eq([case_investigation.tid])

    view_or_conn_or_html
  end

  def submit_place(%View{} = view, %Plug.Conn{} = conn, params),
    do: view |> Pages.submit_and_follow_redirect(conn, "#place-form", place_form: params)
end
