defmodule EpicenterWeb.Test.Pages.CaseInvestigationClinicalDetails do
  import ExUnit.Assertions

  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: id}) do
    conn |> Pages.visit("/case_investigations/#{id}/clinical_details")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-clinical-details")
  end

  def assert_clinical_status_selection(%View{} = view, selections) do
    actual_selections =
      view
      |> Pages.actual_selections("clinical-details-form-clinical-status", "radio")

    assert selections == actual_selections
    view
  end
end
