defmodule EpicenterWeb.Test.Pages.CaseInvestigationIsolationOrder do
  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Test.Pages

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-isolation-order")
  end

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: case_investigation_id}) do
    conn |> Pages.visit("/case-investigations/#{case_investigation_id}/isolation-order")
  end
end
