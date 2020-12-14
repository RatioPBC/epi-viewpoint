defmodule EpicenterWeb.ContactInvestigation do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveComponent.Helpers
  import EpicenterWeb.Presenters.ContactInvestigationPresenter, only: [exposing_case_link: 1, history_items: 1]

  alias Epicenter.Cases.ContactInvestigation
  alias EpicenterWeb.Format
  alias EpicenterWeb.InvestigationNotesSection

  defp status_class(%ContactInvestigation{} = %{interview_status: status}) do
    case status do
      "discontinued" -> "discontinued-status"
      "started" -> "started-status"
      _ -> "pending-status"
    end
  end

  defp status_text(%ContactInvestigation{} = %{interview_status: status}) do
    case status do
      "discontinued" -> "Discontinued"
      "started" -> "Ongoing"
      _ -> "Pending"
    end
  end

  defp interview_buttons(contact_investigation) do
    case contact_investigation.interview_status do
      "pending" ->
        [
          redirect_to(contact_investigation, :start_interview),
          redirect_to(contact_investigation, :discontinue_interview)
        ]

      "started" ->
        [
          redirect_to(contact_investigation, :discontinue_interview)
        ]

      "discontinued" ->
        []
    end
  end

  defp redirect_to(contact_investigation, :discontinue_interview) do
    live_redirect("Discontinue",
      to:
        Routes.contact_investigation_discontinue_path(EpicenterWeb.Endpoint, EpicenterWeb.ContactInvestigationDiscontinueLive, contact_investigation),
      class: "discontinue-link",
      data: [role: "discontinue-contact-investigation"]
    )
  end

  defp redirect_to(contact_investigation, :start_interview) do
    live_redirect("Start interview",
      to:
        Routes.contact_investigation_start_interview_path(
          EpicenterWeb.Endpoint,
          EpicenterWeb.ContactInvestigationStartInterviewLive,
          contact_investigation
        ),
      class: "start-link",
      data: [role: "start-contact-investigation"]
    )
  end
end
