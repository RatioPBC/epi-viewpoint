defmodule EpicenterWeb.Test.Pages.AddVisit do
  import Euclid.Test.Extra.Assertions

  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, case_investigation, place_address),
    do: conn |> Pages.visit("/case-investigations/#{case_investigation.id}/place-addresses/#{place_address.id}/add-visit")

  def assert_here(view_or_conn_or_html, case_investigation, place_address) do
    html =
      view_or_conn_or_html
      |> Pages.assert_on_page("add-visit")
      |> Pages.parse()

    html
    |> Test.Html.attr("[data-page=add-visit]", "data-case-investigation-tid")
    |> assert_eq([case_investigation.tid])

    html
    |> Test.Html.attr("[data-page=add-visit]", "data-place-address-tid")
    |> assert_eq([place_address.tid], returning: view_or_conn_or_html)
  end
end
