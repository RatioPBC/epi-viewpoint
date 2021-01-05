defmodule EpicenterWeb.Test.Pages.ContactInvestigationConcludeQuarantineMonitoring do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("contact-investigation-conclude-quarantine-monitoring")
  end

  def assert_page_heading(%View{} = view, expected_heading) do
    assert view
           |> render()
           |> Test.Html.parse()
           |> Test.Html.text("[data-role=conclude-quarantine-monitoring-heading]") == expected_heading

    view
  end

  def assert_reasons_selection(%View{} = view, expected_selections) do
    assert view |> Pages.actual_selections("conclude-quarantine-monitoring-form-reason", "radio") == expected_selections
    view
  end

  def visit(%Plug.Conn{} = conn, %ContactInvestigation{id: contact_investigation_id}) do
    conn |> Pages.visit("/contact-investigations/#{contact_investigation_id}/conclude-quarantine-monitoring")
  end
end
