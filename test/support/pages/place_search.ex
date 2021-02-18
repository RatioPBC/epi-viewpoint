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
    |> render_change(%{"_target" => ["query"], "query" => "s"})

    view
  end

  def assert_selectable_results(view, expected_texts),
    do:
      view
      |> Pages.parse()
      |> Test.Html.all("[data-role=place-search-result]", as: :text)
      |> assert_eq(expected_texts, returning: view)
end
