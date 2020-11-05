defmodule EpicenterWeb.Test.Pages.CaseInvestigationContact do
  import ExUnit.Assertions
  import Euclid.Test.Extra.Assertions, only: [assert_eq: 2]
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Exposure
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: id}) do
    conn |> Pages.visit("/case_investigations/#{id}/contact")
  end

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: case_investigation_id}, %Exposure{id: id}) do
    conn |> Pages.visit("/case_investigations/#{case_investigation_id}/contact/#{id}")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-contact")
  end

   def change_form(view, attrs) do
     view |> element("#case-investigation-contact-form") |> render_change(attrs)

     view
   end
end
