defmodule EpicenterWeb.Test.Pages.CaseInvestigationIsolationOrder do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-isolation-order")
  end

  def assert_isolation_clearance_order_sent_on(%View{} = view, expected_date_string) do
    assert actual_date(view, "input#isolation_order_form_clearance_order_sent_on") == [expected_date_string]
    view
  end

  def assert_isolation_order_sent_on(%View{} = view, expected_date_string) do
    assert actual_date(view, "input#isolation_order_form_order_sent_on") == [expected_date_string]
    view
  end

  def assert_page_heading(%View{} = view, expected_heading) do
    assert view |> render() |> Test.Html.parse() |> Test.Html.text("[data-test=isolation-order-heading]") == expected_heading
    view
  end

  def change_form(view, attrs) do
    view |> element("#case-investigation-isolation-order-form") |> render_change(attrs)
    view
  end

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: case_investigation_id}) do
    conn |> Pages.visit("/case-investigations/#{case_investigation_id}/isolation-order")
  end

  # # #

  defp actual_date(view, selector) do
    view
    |> Pages.parse()
    |> Test.Html.find(selector)
    |> Test.Html.attr("value")
  end
end
