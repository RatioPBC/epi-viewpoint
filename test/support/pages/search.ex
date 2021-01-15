defmodule EpicenterWeb.Test.Search do
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
end
