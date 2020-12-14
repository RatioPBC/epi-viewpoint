defmodule EpicenterWeb.ContactInvestigation do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveComponent.Helpers
  import EpicenterWeb.Presenters.ContactInvestigationPresenter, only: [exposing_case_link: 1, history_items: 1]

  alias Epicenter.Cases.Exposure
  alias EpicenterWeb.Format
  alias EpicenterWeb.InvestigationNotesSection

  defp status_class(%Exposure{} = %{interview_status: status}) do
    case status do
      "discontinued" -> "discontinued-status"
      "started" -> "started-status"
      _ -> "pending-status"
    end
  end

  defp status_text(%Exposure{} = %{interview_status: status}) do
    case status do
      "discontinued" -> "Discontinued"
      "started" -> "Ongoing"
      _ -> "Pending"
    end
  end

  defp interview_buttons(exposure) do
    case exposure.interview_status do
      "pending" ->
        [
          redirect_to(exposure, :start_interview),
          redirect_to(exposure, :discontinue_interview)
        ]

      "started" ->
        [
          redirect_to(exposure, :discontinue_interview)
        ]

      "discontinued" ->
        []
    end
  end

  defp redirect_to(exposure, :discontinue_interview) do
    live_redirect("Discontinue",
      to: Routes.contact_investigation_discontinue_path(EpicenterWeb.Endpoint, EpicenterWeb.ContactInvestigationDiscontinueLive, exposure),
      class: "discontinue-link",
      data: [role: "discontinue-contact-investigation"]
    )
  end

  defp redirect_to(exposure, :start_interview) do
    live_redirect("Start interview",
      to: Routes.contact_investigation_start_interview_path(EpicenterWeb.Endpoint, EpicenterWeb.ContactInvestigationStartInterviewLive, exposure),
      class: "start-link",
      data: [role: "start-contact-investigation"]
    )
  end
end
