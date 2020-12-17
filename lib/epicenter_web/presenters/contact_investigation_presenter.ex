defmodule EpicenterWeb.Presenters.ContactInvestigationPresenter do
  import Phoenix.LiveView.Helpers
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]

  alias Epicenter.Cases
  alias Epicenter.Cases.ContactInvestigation
  alias EpicenterWeb.Format
  alias EpicenterWeb.PresentationConstants
  alias EpicenterWeb.Router.Helpers, as: Routes

  def exposing_case_link(contact_investigation) do
    exposing_person = contact_investigation.exposing_case.person

    live_redirect(
      "\##{exposing_case_person_id(contact_investigation)}",
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

  defp exposing_case_person_id(contact_investigation) do
    demographic_field(contact_investigation.exposing_case.person, :external_id) ||
      contact_investigation.exposing_case.person.id
  end

  def history_items(contact_investigation) do
    items = []

    items =
      if contact_investigation.interview_completed_at do
        [
          %{
            text: "Completed interview on #{interview_completion_date(contact_investigation)}",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.contact_investigation_complete_interview_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.ContactInvestigationCompleteInterviewLive,
                    contact_investigation
                  ),
                class: "contact-investigation-link",
                data: [role: "contact-investigation-complete-interview-edit-link"]
              )
          }
          | items
        ]
      else
        items
      end

    items =
      if contact_investigation.interview_started_at do
        [
          %{
            text: "Started interview with #{with_interviewee_name(contact_investigation)} on #{interview_start_date(contact_investigation)}",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.contact_investigation_start_interview_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.ContactInvestigationStartInterviewLive,
                    contact_investigation
                  ),
                class: "contact-investigation-link",
                data: [role: "contact-investigation-start-interview-edit-link"]
              )
          }
          | items
        ]
      else
        items
      end

    items =
      if contact_investigation.interview_discontinued_at do
        [
          %{
            text:
              "Discontinued interview on #{
                contact_investigation.interview_discontinued_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()
              }: #{contact_investigation.interview_discontinue_reason}",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.contact_investigation_discontinue_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.ContactInvestigationDiscontinueLive,
                    contact_investigation
                  ),
                class: "contact-investigation-link",
                data: [role: "contact-investigation-discontinue-interview-edit-link"]
              )
          }
          | items
        ]
      else
        items
      end

    items
  end

  defp interview_start_date(contact_investigation),
    do: contact_investigation.interview_started_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()

  defp interview_completion_date(contact_investigation),
    do: contact_investigation.interview_completed_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()

  defp with_interviewee_name(%ContactInvestigation{interview_proxy_name: nil} = contact_investigation),
    do: contact_investigation |> Cases.preload_exposed_person() |> Map.get(:exposed_person) |> Cases.preload_demographics() |> Format.person()

  defp with_interviewee_name(%ContactInvestigation{interview_proxy_name: interview_proxy_name}),
    do: "proxy #{interview_proxy_name}"

  defp convert_to_presented_time_zone(datetime),
    do: DateTime.shift_zone!(datetime, PresentationConstants.presented_time_zone())
end
