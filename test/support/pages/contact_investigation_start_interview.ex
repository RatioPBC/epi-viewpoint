defmodule EpicenterWeb.Test.Pages.ContactInvestigationStartInterview do
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.Exposure
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %Exposure{id: exposure_id}) do
    conn |> Pages.visit("/contact-investigations/#{exposure_id}/start-interview")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html
    |> Pages.assert_on_page("contact-investigation-start-interview")

    view_or_conn_or_html
  end

  def change_form(%View{} = view, params) do
    view |> form("[data-role=start-interview-form]", params) |> render_change()
    view
  end
end
