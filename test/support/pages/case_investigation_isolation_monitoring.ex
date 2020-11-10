defmodule EpicenterWeb.Test.Pages.CaseInvestigationIsolationMonitoring do
  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: case_investigation_id}) do
    conn |> Pages.visit("/case_investigations/#{case_investigation_id}/isolation_monitoring")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-isolation-monitoring")
  end
end
