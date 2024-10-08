defmodule EpiViewpointWeb.Test.Pages.ContactInvestigationQuarantineMonitoring do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias EpiViewpoint.ContactInvestigations.ContactInvestigation
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %ContactInvestigation{id: id}) do
    conn |> Pages.visit("/contact-investigations/#{id}/quarantine-monitoring")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("contact-investigation-quarantine-monitoring")
  end

  def assert_page_title(%View{} = view, expected_page_title) do
    assert view
           |> Pages.parse()
           |> Test.Html.text(role: "quarantine-page-title") == expected_page_title
  end

  def assert_quarantine_date_started(%View{} = view, expected_date, expected_explanation_text) do
    assert view
           |> Pages.parse()
           |> Test.Html.find!("input#contact-investigation-quarantine-monitoring-form_date_started")
           |> Test.Html.attr("value") == [expected_date]

    assert view
           |> Pages.parse()
           |> Test.Html.text(role: "exposed-date") == expected_explanation_text

    view
  end

  def assert_quarantine_date_ended(%View{} = view, expected_date) do
    assert view
           |> Pages.parse()
           |> Test.Html.find!("input#contact-investigation-quarantine-monitoring-form_date_ended")
           |> Test.Html.attr("value") == [expected_date]

    view
  end

  def assert_quarantine_recommended_length(%View{} = view, expected_text) do
    assert view
           |> Pages.parse()
           |> Test.Html.text(role: "recommended-length") == expected_text

    view
  end

  def change_form(view, attrs) do
    view |> element("#contact-investigation-quarantine-monitoring-form") |> render_change(attrs)

    view
  end
end
