defmodule EpicenterWeb.Test.Pages.PlaceSearch do
  import Euclid.Test.Extra.Assertions
  alias EpicenterWeb.Test.Pages
  alias Epicenter.Test

  def visit(%Plug.Conn{} = conn, case_investigation),
    do: conn |> Pages.visit("/case-investigations/#{case_investigation.id}/place-search")

  def assert_here(view_or_conn_or_html, case_investigation),
    do:
      view_or_conn_or_html
      |> Pages.assert_on_page("place-search")
      |> Pages.parse()
      |> Test.Html.attr("[data-page=place-search]", "data-tid")
      |> assert_eq([case_investigation.tid])
end
