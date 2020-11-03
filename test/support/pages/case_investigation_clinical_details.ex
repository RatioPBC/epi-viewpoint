defmodule EpicenterWeb.Test.Pages.CaseInvestigationClinicalDetails do
  import ExUnit.Assertions
  import Euclid.Test.Extra.Assertions, only: [assert_eq: 2]
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: id}) do
    conn |> Pages.visit("/case_investigations/#{id}/clinical_details")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-clinical-details")
  end

  def assert_symptom_onset_date_value(%View{} = view, value) do
    html =
      view
      |> render()
      |> Test.Html.parse()

    html
    |> Test.Html.attr("#clinical_details_form_symptom_onset_date", "value")
    |> assert_eq([value])

    assert html |> Test.Html.text("#case-investigation-clinical-details") =~
             "If asymptomatic, date of first positive test (#{value})"

    view
  end

  def assert_clinical_status_selection(%View{} = view, selections) do
    actual_selections =
      view
      |> Pages.actual_selections("clinical-details-form-clinical-status", "radio")

    assert selections == actual_selections
    view
  end

  def assert_symptoms_selection(%View{} = view, selections) do
    actual_selections =
      view
      |> Pages.actual_selections("clinical-details-form-symptoms", "checkbox")

    assert selections == actual_selections
    view
  end
end
