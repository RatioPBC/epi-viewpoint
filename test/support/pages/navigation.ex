defmodule EpicenterWeb.Test.Pages.Navigation do
  import ExUnit.Assertions

  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  def assert_has_menu_item(view_or_conn_or_html, menu_item) do
    assert menu_item in menu_items(view_or_conn_or_html)
  end

  def assert_has_search_field(view_or_conn_or_html) do
    view_or_conn_or_html
    |> Pages.parse()
    |> Test.Html.find!("#search-form")

    view_or_conn_or_html
  end

  def refute_has_menu_item(view_or_conn_or_html, menu_item) do
    refute menu_item in menu_items(view_or_conn_or_html)
  end

  defp menu_items(view_or_conn_or_html),
    do:
      view_or_conn_or_html
      |> Pages.parse()
      |> Test.Html.all("#user-menu li", as: :text)
end
