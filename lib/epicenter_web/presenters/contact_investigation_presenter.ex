defmodule EpicenterWeb.Presenters.ContactInvestigationPresenter do
  import Phoenix.LiveView.Helpers
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]

  alias Epicenter.Cases
  alias Epicenter.Cases.Exposure
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
      if exposure.interview_started_at do
        [
          %{
            text: "Started interview with #{with_interviewee_name(exposure)} on #{interview_start_date(exposure)}",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.contact_investigation_start_interview_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.ContactInvestigationStartInterviewLive,
                    exposure
                  ),
                class: "contact-investigation-link"
              )
          }
          | items
        ]
      else
        items
      end

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

  defp interview_start_date(exposure),
    do: exposure.interview_started_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()

  defp with_interviewee_name(%Exposure{interview_proxy_name: nil} = exposure),
    do: exposure |> Cases.preload_exposed_person() |> Map.get(:exposed_person) |> Cases.preload_demographics() |> Format.person()

  defp with_interviewee_name(%Exposure{interview_proxy_name: interview_proxy_name}),
    do: "proxy #{interview_proxy_name}"

  defp convert_to_presented_time_zone(datetime),
    do: DateTime.shift_zone!(datetime, PresentationConstants.presented_time_zone())
end
