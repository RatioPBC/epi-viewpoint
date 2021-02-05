defmodule EpicenterWeb.Test.Pages.Search do
  import Euclid.Test.Extra.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Epicenter.Test.HtmlAssertions

  def assert_no_results(view, search_term) do
    view
    |> render()
    |> Test.Html.parse()
    |> HtmlAssertions.assert_text("no-search-results", "No results found for")
    |> HtmlAssertions.assert_text("no-search-results", search_term)

    view
  end

  def assert_results(view, _tids) do
    view
    |> render()
    |> Test.Html.parse()
    |> HtmlAssertions.assert_text("search-results", "results")

    view
  end

  def assert_search_term_in_search_box(view, search_term) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.attr("[data-role=search-term-input]", "value")
    |> assert_eq([search_term], returning: view)
  end

  def close_search_results(view) do
    view
    |> element("[data-role=close-search-results]")
    |> render_click()

    view
  end
end
