defmodule EpicenterWeb.Test.Pages.ContactInvestigationCompleteInterview do
  alias Epicenter.Cases.ContactInvestigation
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, %ContactInvestigation{id: id}) do
    conn |> Pages.visit("/contact-investigations/#{id}/complete-interview")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("contact-investigation-complete-interview")
  end
end
