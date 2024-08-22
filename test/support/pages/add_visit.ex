defmodule EpiViewpointWeb.Test.Pages.AddVisit do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions

  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, case_investigation, place, place_address),
    do: conn |> Pages.visit("/case-investigations/#{case_investigation.id}/add-visit?place=#{place.id}&place_address=#{place_address.id}")

  def assert_here(view_or_conn_or_html, case_investigation, place_address) do
    html =
      view_or_conn_or_html
      |> Pages.assert_on_page("add-visit")
      |> Pages.parse()

    html
    |> Test.Html.attr("[data-page=add-visit]", "data-case-investigation-tid")
    |> assert_eq([case_investigation.tid])

    assert html |> Test.Html.text("[data-role=place-address]") |> String.starts_with?(place_address.street)

    view_or_conn_or_html
  end

  def assert_onset_date(view, date_string) do
    view
    |> Pages.parse()
    |> Test.Html.text("[data-role=onset-date]")
    |> assert_eq(date_string)

    view
  end

  def assert_place_name_and_address(view, name, address) do
    html =
      view
      |> Pages.parse()

    html
    |> Test.Html.text("[data-role=place-name]")
    |> assert_eq(name)

    html
    |> Test.Html.text("[data-role=place-address]")
    |> assert_eq(address, returning: view)
  end
end
