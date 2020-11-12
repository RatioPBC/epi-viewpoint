defmodule EpicenterWeb.Test.Pages.CaseInvestigationConcludeIsolationMonitoring do
  #  import ExUnit.Assertions
  #  import Phoenix.LiveViewTest

  alias Epicenter.Cases.CaseInvestigation
  #  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  #  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: case_investigation_id}) do
    conn |> Pages.visit("/case-investigations/#{case_investigation_id}/conclude-isolation-monitoring")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-conclude-isolation-monitoring")
  end
end
