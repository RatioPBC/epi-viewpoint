defmodule EpicenterWeb.Test.Components.ContactInvestigation do
  import Euclid.Test.Extra.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Phoenix.LiveViewTest.View

  def assert_clinical_details(%View{} = view, expected_values) do
    parsed_html =
      view
      |> render()
      |> Test.Html.parse()

    parsed_html |> Test.Html.find!(".contact-investigation .clinical-details")

    with clinical_status when not is_nil(clinical_status) <- Map.get(expected_values, :clinical_status) do
      parsed_html
      |> Test.Html.find("[data-role=contact-investigation-clinical-status-text]")
      |> Test.Html.text()
      |> assert_eq(clinical_status)
    end

    with symptom_onset_on when not is_nil(symptom_onset_on) <- Map.get(expected_values, :symptom_onset_on) do
      parsed_html
      |> Test.Html.find("[data-role=contact-investigation-exposed-on-date-text]")
      |> Test.Html.text()
      |> assert_eq(symptom_onset_on)
    end

    with symptoms when not is_nil(symptoms) <- Map.get(expected_values, :symptoms) do
      parsed_html
      |> Test.Html.find("[data-role=contact-investigation-symptoms-text]")
      |> Test.Html.text()
      |> assert_eq(symptoms)
    end

    view
  end
end
