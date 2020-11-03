defmodule EpicenterWeb.Profile.CaseInvestigationPresenter do
  import Phoenix.LiveView.Helpers

  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Format
  alias EpicenterWeb.PresentationConstants
  alias EpicenterWeb.Router.Helpers, as: Routes

  def interview_buttons(case_investigation) do
    case CaseInvestigation.status(case_investigation) do
      :pending ->
        [
          redirect_to(case_investigation, :start_interview),
          redirect_to(case_investigation, :discontinue_interview)
        ]

      :started ->
        [
          redirect_to(case_investigation, :discontinue_interview)
        ]

      :discontinued ->
        []
    end
  end

  def history_items(case_investigation) do
    items = []

    items =
      if case_investigation.started_at do
        [
          %{
            text: "Started interview with #{with_interviewee_name(case_investigation)} on #{interview_start_date(case_investigation)}",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.case_investigation_start_interview_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationStartInterviewLive,
                    case_investigation
                  ),
                class: "case-investigation-link"
              )
          }
          | items
        ]
      else
        items
      end

    items =
      if case_investigation.discontinue_reason != nil do
        [
          %{
            text:
              "Discontinued interview on #{case_investigation.discontinued_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()}: #{
                case_investigation.discontinue_reason
              }",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.case_investigation_discontinue_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationDiscontinueLive,
                    case_investigation
                  ),
                id: "edit-discontinue-case-investigation-link-001",
                class: "discontinue-case-investigation-link"
              )
          }
          | items
        ]
      else
        items
      end

    items |> Enum.reverse()
  end

  defp convert_to_presented_time_zone(datetime),
    do: DateTime.shift_zone!(datetime, PresentationConstants.presented_time_zone())

  defp interview_start_date(case_investigation),
    do: case_investigation.started_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()

  defp redirect_to(case_investigation, :start_interview) do
    live_redirect("Start interview",
      to: Routes.case_investigation_start_interview_path(EpicenterWeb.Endpoint, EpicenterWeb.CaseInvestigationStartInterviewLive, case_investigation),
      id: "start-interview-case-investigation-link-001",
      class: "start-interview-case-investigation-link"
    )
  end

  defp redirect_to(case_investigation, :discontinue_interview) do
    live_redirect("Discontinue",
      to: Routes.case_investigation_discontinue_path(EpicenterWeb.Endpoint, EpicenterWeb.CaseInvestigationDiscontinueLive, case_investigation),
      id: "discontinue-case-investigation-link-001",
      class: "discontinue-case-investigation-link"
    )
  end

  defp with_interviewee_name(%CaseInvestigation{interview_proxy_name: nil} = case_investigation),
    do: case_investigation |> Cases.preload_person() |> Map.get(:person) |> Cases.preload_demographics() |> Format.person()

  defp with_interviewee_name(%CaseInvestigation{interview_proxy_name: interview_proxy_name}),
    do: "proxy #{interview_proxy_name}"
end
