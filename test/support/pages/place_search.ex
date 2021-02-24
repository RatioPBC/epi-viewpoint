defmodule EpicenterWeb.Test.Pages.PlaceSearch do
  import Euclid.Test.Extra.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, case_investigation),
    do: conn |> Pages.visit("/case-investigations/#{case_investigation.id}/place-search")

  def assert_here(view_or_conn_or_html, case_investigation),
    do:
      view_or_conn_or_html
      |> Pages.assert_on_page("place-search")
      |> Pages.parse()
      |> Test.Html.attr("[data-page=place-search]", "data-tid")
      |> assert_eq([case_investigation.tid], returning: view_or_conn_or_html)

  def type_in_the_search_box(view, text) do
    view
    |> element("[data-role=place-search-form]")
    |> render_change(%{"_target" => ["query"], "query" => text})

    view
  end

  def assert_selectable_results(view, expected_texts),
    do:
      view
      |> Pages.parse()
      |> Test.Html.all("[data-role=place-search-result]", as: :text)
      |> assert_eq(expected_texts, returning: view)

  def click_add_new_place_and_follow_redirect(view, conn) do
    view
    |> element("[data-role=add-new-place]")
    |> render_click()
    |> Pages.assert_redirect_succeeded()
    |> Pages.follow_live_view_redirect(conn)
  end

  def click_result_and_follow_redirect(view, conn, place_address_tid) do
    view
    |> element("[data-role=place_address_link][data-tid=#{place_address_tid}]")
    |> render_click()
    |> Pages.assert_redirect_succeeded()
    |> Pages.follow_live_view_redirect(conn)
  end
end
