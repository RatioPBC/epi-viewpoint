defmodule EpicenterWeb.Presenters.ContactInvestigationPresenter do
  import Phoenix.LiveView.Helpers
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]

  alias EpicenterWeb.Format
  alias EpicenterWeb.PresentationConstants
  alias EpicenterWeb.Router.Helpers, as: Routes

  def exposing_case_link(exposure) do
    exposing_person = exposure.exposing_case.person

    live_redirect(
      "\##{exposing_case_person_id(exposure)}",
      to:
        Routes.profile_path(
          EpicenterWeb.Endpoint,
          EpicenterWeb.ProfileLive,
          exposing_person
        ),
      data: [role: "visit-exposing-case-link"],
      class: "visit-exposing-case-link"
    )
  end

  defp exposing_case_person_id(exposure) do
    demographic_field(exposure.exposing_case.person, :external_id) ||
      exposure.exposing_case.person.id
  end

  def history_items(exposure) do
    items = []

    items =
      if exposure.interview_discontinued_at do
        [
          %{
            text:
              "Discontinued interview on #{exposure.interview_discontinued_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()}: #{
                exposure.interview_discontinue_reason
              }",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.contact_investigation_discontinue_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.ContactInvestigationDiscontinueLive,
                    exposure
                  ),
                class: "contact-investigation-link",
                data: [role: "edit-discontinue-contact-investigation-interview-link"]
              )
          }
          | items
        ]
      else
        items
      end

    items
  end

  defp convert_to_presented_time_zone(datetime),
    do: DateTime.shift_zone!(datetime, PresentationConstants.presented_time_zone())
end
