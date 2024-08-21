defmodule EpiViewpointWeb.Test.Pages.ContactInvestigationClinicalDetails do
  import ExUnit.Assertions
  import Euclid.Test.Extra.Assertions, only: [assert_eq: 2]
  import Phoenix.LiveViewTest

  alias EpiViewpoint.ContactInvestigations.ContactInvestigation
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

  alias Phoenix.LiveViewTest.View

  @form_id "contact-investigation-clinical-details-form"

  def visit(%Plug.Conn{} = conn, %ContactInvestigation{id: id}) do
    conn |> Pages.visit("/contact-investigations/#{id}/clinical-details")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("contact-investigation-clinical-details")
    view_or_conn_or_html
  end

  def assert_clinical_status_selection(%View{} = view, selections) do
    actual_selections =
      view
      |> Pages.actual_selections("clinical-details-form-clinical-status", "radio")

    assert selections == actual_selections
    view
  end

  def assert_exposed_on_explanation_text(%View{} = view, date) do
    html =
      view
      |> render()
      |> Test.Html.parse()

    assert html |> Test.Html.text("#contact-investigation-clinical-details") =~
             "Last together with an initiating index case on #{date}"

    view
  end

  def assert_exposed_on_value(%View{} = view, value) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.attr("##{@form_id}_exposed_on", "value")
    |> assert_eq([value])

    view
  end

  def assert_symptoms_selection(%View{} = view, selections) do
    actual_selections =
      view
      |> Pages.actual_selections("clinical-details-form-symptoms", "checkbox")

    assert selections == actual_selections
    view
  end

  def assert_save_button_visible(%View{} = view) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.text("button[type=submit]")
    |> assert_eq("Save")

    view
  end

  def change_form(view, attrs) do
    view |> element("#contact-investigation-clinical-details-form") |> render_change(attrs)

    view
  end
end
