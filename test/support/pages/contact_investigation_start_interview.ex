defmodule EpicenterWeb.Test.Pages.ContactInvestigationStartInterview do
  alias Epicenter.Cases.Exposure
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, %Exposure{id: case_investigation_id}) do
    conn |> Pages.visit("/exposure/#{case_investigation_id}/start-interview")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html
    |> Pages.assert_on_page("contact-investigation-start-interview")

    view_or_conn_or_html
  end
end
