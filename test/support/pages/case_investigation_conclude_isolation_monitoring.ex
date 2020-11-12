defmodule EpicenterWeb.Test.Pages.CaseInvestigationConcludeIsolationMonitoring do
  import ExUnit.Assertions

  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-conclude-isolation-monitoring")
  end

  def assert_reasons_selection(%View{} = view, expected_selections) do
    assert view |> Pages.actual_selections("conclude-isolation-monitoring-form-reason", "radio") == expected_selections
    view
  end

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: case_investigation_id}) do
    conn |> Pages.visit("/case-investigations/#{case_investigation_id}/conclude-isolation-monitoring")
  end
end
