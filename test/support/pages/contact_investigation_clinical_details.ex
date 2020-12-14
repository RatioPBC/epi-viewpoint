defmodule EpicenterWeb.Test.Pages.ContactInvestigationClinicalDetails do
  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: id}) do
    conn |> Pages.visit("/contact-investigations/#{id}/clinical-details")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("contact-investigation-clinical-details")
    view_or_conn_or_html
  end
end
