defmodule EpicenterWeb.Test.Pages.Search do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Epicenter.Test.HtmlAssertions
  alias Phoenix.LiveViewTest.View

  def assert_no_results(view, search_term) do
    view
    |> render()
    |> Test.Html.parse()
    |> HtmlAssertions.assert_text("no-search-results", "No results found for")
    |> HtmlAssertions.assert_text("no-search-results", search_term)

    view
  end

  def assert_results(view, tids) do
    view
    |> render()
    |> Test.Html.parse()
    |> assert_results_visible(true)
    |> Test.Html.all("[data-role=search-result]", as: :tids)
    |> assert_eq(tids, ignore_order: true, returning: view)
  end

  def assert_results_visible(%View{} = view, expected_visible?) do
    view
    |> render()
    |> Test.Html.parse()
    |> assert_results_visible(expected_visible?)

    view
  end

  def assert_results_visible(parsed_html, expected_visible?) do
    results_element = parsed_html |> Test.Html.find("[data-role=search-results]")

    if expected_visible? do
      assert length(results_element) > 0
    else
      assert results_element == []
    end

    parsed_html
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

  def search(view, term) do
    view
    |> form("[data-role=app-search] form", %{search: %{"term" => term}})
    |> render_change()

    view
  end
end
