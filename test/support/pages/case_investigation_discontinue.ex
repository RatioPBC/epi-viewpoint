defmodule EpicenterWeb.Test.Pages.CaseInvestigationDiscontinue do
  import ExUnit.Assertions

  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: case_investigation_id}) do
    conn |> Pages.visit("/case-investigations/#{case_investigation_id}/discontinue")
  end

  def assert_reason_selections(%View{} = view, expected_reasons) do
    assert Pages.actual_selections(view, "case-investigation-interview-discontinue-reason", "radio") == expected_reasons
    view
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-discontinue")
  end
end
