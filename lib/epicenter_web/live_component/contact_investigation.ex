defmodule EpicenterWeb.ContactInvestigation do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveComponent.Helpers
  import EpicenterWeb.Presenters.ContactInvestigationPresenter, only: [exposing_case_link: 1, history_items: 1]
  import EpicenterWeb.Presenters.InvestigationPresenter, only: [displayable_clinical_status: 1, displayable_symptoms: 1]

  alias Epicenter.Cases.ContactInvestigation
  alias EpicenterWeb.Format
  alias EpicenterWeb.InvestigationNotesSection

  defp status_class(status) do
    case status do
      "completed" -> "completed-status"
      "discontinued" -> "discontinued-status"
      "started" -> "started-status"
      "ongoing" -> "started-status"
      _ -> "pending-status"
    end
  end

  defp status_text(%ContactInvestigation{} = %{interview_status: status}) do
    case status do
      "completed" -> "Completed"
      "discontinued" -> "Discontinued"
      "started" -> "Ongoing"
      _ -> "Pending"
    end
  end

  defp quarantine_monitoring_status_text(%ContactInvestigation{} = %{quarantine_monitoring_status: status}) do
    case status do
      "ongoing" -> "Ongoing"
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
          redirect_to(contact_investigation, :complete_interview),
          redirect_to(contact_investigation, :discontinue_interview)
        ]

      "completed" ->
        []

      "discontinued" ->
        []
    end
  end

  defp redirect_to(contact_investigation, :complete_interview) do
    live_redirect("Complete interview",
      to:
        Routes.contact_investigation_complete_interview_path(
          EpicenterWeb.Endpoint,
          :complete_contact_investigation,
          contact_investigation
        ),
      class: "primary",
      data: [role: "contact-investigation-complete-interview-link"]
    )
  end

  defp redirect_to(contact_investigation, :discontinue_interview) do
    live_redirect("Discontinue",
      to:
        Routes.contact_investigation_discontinue_path(EpicenterWeb.Endpoint, EpicenterWeb.ContactInvestigationDiscontinueLive, contact_investigation),
      class: "discontinue-link",
      data: [role: "contact-investigation-discontinue-interview"]
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
      class: "primary",
      data: [role: "contact-investigation-start-interview"]
    )
  end

  def quarantine_monitoring_button(contact_investigation) do
    case contact_investigation.quarantine_monitoring_status do
      "pending" ->
        live_redirect("Add quarantine dates",
          to:
            Routes.contact_investigation_quarantine_monitoring_path(
              EpicenterWeb.Endpoint,
              EpicenterWeb.ContactInvestigationQuarantineMonitoringLive,
              contact_investigation
            ),
          class: "primary",
          data: [role: "contact-investigation-quarantine-monitoring-start-link"]
        )

      "ongoing" ->
        nil

      "concluded" ->
        nil
    end
  end
end
