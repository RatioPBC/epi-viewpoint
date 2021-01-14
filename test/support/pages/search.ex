defmodule EpicenterWeb.Test.Search do
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Epicenter.Test.HtmlAssertions
  alias EpicenterWeb.Test.Pages

  def assert_no_results(view) do
    view
    |> Pages.assert_on_page("search-results")
    |> render()
    |> Test.Html.parse()
    |> HtmlAssertions.assert_text("no-search-results", "No results ")

    view
  end
end
