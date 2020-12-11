defmodule EpicenterWeb.ContactInvestigation do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveComponent.Helpers
  import EpicenterWeb.Presenters.ContactInvestigationPresenter, only: [exposing_case_link: 1, history_items: 1]

  alias Epicenter.Cases.Exposure
  alias EpicenterWeb.Format
  alias EpicenterWeb.InvestigationNotesSection

  def render(assigns) do
    ~H"""
    section.contact-investigation data-role="contact-investigation" data-exposure-id="#{@exposure.id}" data-tid="#{@exposure.tid}"
      header
        h2 data-role="contact-investigation-title" Contact investigation #{Format.date(@exposure.most_recent_date_together)}
        span.contact-investigation-timestamp data-role="contact-investigation-timestamp" Created on #{Format.date(@exposure.inserted_at)}
      div
        div data-role="initiating-case"
          span Initiated by index case
          = exposing_case_link(@exposure)
        = if @exposure.under_18 do
          ul.dotted-details data-role="minor-details"
            li data-role="detail" Minor
            li data-role="detail" Guardian: #{@exposure.guardian_name}
            li data-role="detail" Guardian phone: #{Format.phone(@exposure.guardian_phone)}
        ul.dotted-details data-role="exposure-details"
          = if @exposure.household_member do
            li data-role="detail" Same household
          li data-role="detail" #{@exposure.relationship_to_case}
          li data-role="detail" Last together on #{Format.date(@exposure.most_recent_date_together)}
      .contact-investigation-notes
        = component @socket,
                    InvestigationNotesSection,
                    @exposure.id <> "note section",
                    subject: @exposure,
                    notes: @exposure.notes,
                    current_user_id: @current_user_id,
                    on_add_note: @on_add_note,
                    on_delete_note: @on_delete_note
      div
        .contact-investigation-status-row
          h3
            span data-role="contact-investigation-status" class=status_class(@exposure) = status_text(@exposure)
            |  interview
          div.contact-investigation-interview-buttons
            = for button <- interview_buttons(@exposure) do
              span data-role="contact-investigation-interview-button"
                = button
      .contact-investigation-history
        = for history_item <- history_items(@exposure) do
          div
            span data-role="contact-investigation-history-item-text" = history_item.text
            span class="history-item-link" = history_item.link
    """
  end

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
