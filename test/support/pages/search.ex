defmodule EpiViewpointWeb.Test.Pages.Search do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias EpiViewpoint.Test
  alias EpiViewpoint.Test.HtmlAssertions
  alias Phoenix.LiveViewTest.View

  def assert_disabled(view, link) when link in ~w[prev next]a do
    assert view |> render() |> Test.Html.parse() |> Test.Html.attr("[data-role=search-#{link}]", "disabled") == ["disabled"]
    view
  end

  def assert_no_results(view, search_term) do
    view
    |> render()
    |> Test.Html.parse()
    |> HtmlAssertions.assert_contains_text("no-search-results", "No results found for")
    |> HtmlAssertions.assert_contains_text("no-search-results", search_term)

    view
  end

  def assert_results(view, search_result_rows) do
    view
    |> render()
    |> Test.Html.parse()
    |> assert_results_visible(true)
    |> Test.Html.all("[data-role=search-result]", fn search_result ->
      [
        Test.Html.text(search_result, "[data-role=search-result-name"),
        Test.Html.text(search_result, "[data-role=search-result-details"),
        Test.Html.text(search_result, "[data-role=search-result-labs")
      ]
    end)
    |> assert_eq(search_result_rows, returning: view)
  end

  def assert_results_tids(view, expected_tids) do
    view
    |> render()
    |> Test.Html.parse()
    |> assert_results_visible(true)
    |> Test.Html.all("[data-role=search-result]", as: :tids)
    |> assert_eq(expected_tids, returning: view)
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

  def click_next(view) do
    view |> element("[data-role=search-next]") |> render_click()
    view
  end

  def click_page_number(view, page_number) do
    view |> element("[data-page-number=#{page_number}]") |> render_click()
    view
  end

  def click_prev(view) do
    view |> element("[data-role=search-prev]") |> render_click()
    view
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
