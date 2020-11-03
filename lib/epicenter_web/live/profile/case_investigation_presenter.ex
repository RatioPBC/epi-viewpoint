defmodule EpicenterWeb.Profile.CaseInvestigationPresenter do
  alias Epicenter.Format
  alias EpicenterWeb.PresentationConstants
  alias EpicenterWeb.Router.Helpers, as: Routes

  import Phoenix.LiveView.Helpers

  def interview_buttons(case_investigation, person) do
    case case_investigation.discontinue_reason do
      nil ->
        [
          live_redirect("Start interview",
            to:
              Routes.case_investigation_start_interview_path(
                EpicenterWeb.Endpoint,
                EpicenterWeb.CaseInvestigationStartInterviewLive,
                person,
                case_investigation
              ),
            id: "start-interview-case-investigation-link-001",
            class: "start-interview-case-investigation-link"
          ),
          live_redirect("Discontinue",
            to:
              Routes.case_investigation_discontinue_path(
                EpicenterWeb.Endpoint,
                EpicenterWeb.CaseInvestigationDiscontinueLive,
                person,
                case_investigation
              ),
            id: "discontinue-case-investigation-link-001",
            class: "discontinue-case-investigation-link"
          )
        ]

      _ ->
        []
    end
  end

  def history_items(case_investigation, person) do
    items = []

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
                    person,
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

    items
  end

  defp convert_to_presented_time_zone(datetime) do
    DateTime.shift_zone!(datetime, PresentationConstants.presented_time_zone())
  end
end