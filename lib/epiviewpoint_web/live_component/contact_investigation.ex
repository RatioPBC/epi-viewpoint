defmodule EpiViewpointWeb.ContactInvestigation do
  use EpiViewpointWeb, :live_component
  use Phoenix.Component

  import EpiViewpointWeb.Presenters.ContactInvestigationPresenter, only: [exposing_case_link: 1, history_items: 1, quarantine_history_items: 1]
  import EpiViewpointWeb.Presenters.InvestigationPresenter, only: [displayable_clinical_status: 1, displayable_symptoms: 1]
  import EpiViewpointWeb.Presenters.PeoplePresenter, only: [is_editable?: 1]

  alias EpiViewpoint.ContactInvestigations.ContactInvestigation
  alias EpiViewpointWeb.Format
  alias EpiViewpointWeb.InvestigationNotesSection

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

  defp quarantine_monitoring_status_text(
         %{quarantine_monitoring_status: status, quarantine_monitoring_ends_on: quarantine_monitoring_ends_on},
         current_date
       ) do
    content_tag :h3, class: "contact-investigation-quarantine-monitoring-status", data_role: "contact-investigation-quarantine-monitoring-status" do
      case status do
        "ongoing" ->
          diff = Date.diff(quarantine_monitoring_ends_on, current_date)

          [
            content_tag(:span, "Ongoing", class: "started-status"),
            content_tag(:span, "quarantine monitoring (#{diff} days remaining)")
          ]

        "concluded" ->
          [
            content_tag(:span, "Concluded", class: "completed-status"),
            content_tag(:span, "quarantine monitoring")
          ]

        _ ->
          [
            content_tag(:span, "Pending", class: "pending-status"),
            content_tag(:span, "quarantine monitoring")
          ]
      end
    end
  end

  attr :contact_investigation, :any, required: true

  def interview_buttons(assigns) do
    ~H"""
    <%= for label <- to_interview_buttons_list(@contact_investigation) do %>
      <span data-role="contact-investigation-interview-button">
        <.interview_buttons_router_link label={label} contact_investigation={@contact_investigation} />
      </span>
    <% end %>
    """
  end

  attr :label, :any, required: true
  attr :contact_investigation, :any, required: true

  def interview_buttons_router_link(assigns) do
    ~H"""
    <.link
      :if={@label == :start_interview}
      navigate={~p"/contact-investigations/#{@contact_investigation}/start-interview"}
      class="primary"
      data-role="contact-investigation-start-interview"
    >
      Start interview
    </.link>

    <.link
      :if={@label == :complete_interview}
      navigate={~p"/contact-investigations/#{@contact_investigation}/complete-interview"}
      class="primary"
      data-role="contact-investigation-complete-interview-link"
    >
      Complete interview
    </.link>

    <.link
      :if={@label == :discontinue_interview}
      navigate={~p"/contact-investigations/#{@contact_investigation}/discontinue"}
      class="discontinue-link"
      data-role="contact-investigation-discontinue-interview"
    >
      Discontinue
    </.link>
    """
  end

  attr :contact_investigation, :any, required: true

  def quarantine_monitoring_button(assigns) do
    ~H"""
    <.link
      :if={@contact_investigation.quarantine_monitoring_status == "pending"}
      navigate={~p"/contact-investigations/#{@contact_investigation}/quarantine-monitoring"}
      class="primary"
      data-role="contact-investigation-quarantine-monitoring-start-link"
    >
      Add quarantine dates
    </.link>

    <.link
      :if={@contact_investigation.quarantine_monitoring_status == "ongoing"}
      navigate={~p"/contact-investigations/#{@contact_investigation}/conclude-quarantine-monitoring"}
      class="primary"
      data-role="conclude-contact-investigation-quarantine-monitoring-link"
    >
      Conclude monitoring
    </.link>
    """
  end

  defp to_interview_buttons_list(contact_investigation) do
    case is_editable?(contact_investigation.exposed_person) do
      false ->
        []

      true ->
        case contact_investigation.interview_status do
          "pending" ->
            [:start_interview, :discontinue_interview]

          "started" ->
            [:complete_interview, :discontinue_interview]

          "completed" ->
            []

          "discontinued" ->
            []
        end
    end
  end
end
