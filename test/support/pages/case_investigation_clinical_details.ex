defmodule EpicenterWeb.Test.Pages.CaseInvestigationClinicalDetails do
  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: id}) do
    conn |> Pages.visit("/case_investigations/#{id}/clinical_details")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-clinical-details")
  end
end
