defmodule EpicenterWeb.Presenters.ContactInvestigationPresenter do
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]

  use EpicenterWeb, :presenter

  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.ContactInvestigations
  alias EpicenterWeb.Presenters.PeoplePresenter

  attr :contact_investigation, :any, required: true

  def exposing_case_link(assigns) do
    ~H"""
    <.link navigate={~p"/people/#{@contact_investigation.exposing_case.person}"} data-role="visit-exposing-case-link" class="visit-exposing-case-link">
      <%= "\##{exposing_case_person_id(@contact_investigation)}" %>
    </.link>
    """
  end

  defp exposing_case_person_id(contact_investigation) do
    demographic_field(contact_investigation.exposing_case.person, :external_id) ||
      contact_investigation.exposing_case.person.id
  end

  attr :contact_investigation, :any, required: true

  def history_items(assigns) do
    ~H"""
    <div class="contact-investigation-history">
      <%= for item <- to_history_items_list(@contact_investigation) do %>
        <div>
          <span data-role="contact-investigation-history-item-text"><%= item.text %></span>
          <span class="history-item-link"><.history_router_link label={item.link} contact_investigation={@contact_investigation} /></span>
        </div>
      <% end %>
    </div>
    """
  end

  attr :label, :any, required: true
  attr :contact_investigation, :any, required: true

  def history_router_link(assigns) do
    ~H"""
    <.link
      :if={@label == :start_interview}
      navigate={~p"/contact-investigations/#{@contact_investigation}/start-interview"}
      data-role="contact-investigation-start-interview-edit-link"
      class="contact-investigation-link"
    >
      Edit
    </.link>

    <.link
      :if={@label == :complete_interview}
      navigate={~p"/contact-investigations/#{@contact_investigation}/complete-interview"}
      data-role="contact-investigation-complete-interview-edit-link"
      class="contact-investigation-link"
    >
      Edit
    </.link>

    <.link
      :if={@label == :discontinue_interview}
      navigate={~p"/contact-investigations/#{@contact_investigation}/discontinue"}
      data-role="contact-investigation-discontinue-interview-edit-link"
      class="contact-investigation-link"
    >
      Edit
    </.link>
    """
  end

  def to_history_items_list(contact_investigation) do
    [
      interview_started_at_history(contact_investigation),
      interview_completed_at_history(contact_investigation),
      interview_discontinued_at_history(contact_investigation)
    ]
    |> Enum.filter(&Function.identity/1)
  end

  defp interview_started_at_history(%{interview_started_at: nil}), do: nil

  defp interview_started_at_history(contact_investigation) do
    %{
      text: "Started interview with #{with_interviewee_name(contact_investigation)} on #{format_date(contact_investigation.interview_started_at)}",
      link:
        link_if_editable(
          contact_investigation.exposed_person,
          :start_interview
        )
    }
  end

  defp interview_completed_at_history(%{interview_completed_at: nil}), do: nil

  defp interview_completed_at_history(contact_investigation) do
    %{
      text: "Completed interview on #{format_date(contact_investigation.interview_completed_at)}",
      link:
        link_if_editable(
          contact_investigation.exposed_person,
          :complete_interview
        )
    }
  end

  defp interview_discontinued_at_history(%{interview_discontinued_at: nil}), do: nil

  defp interview_discontinued_at_history(contact_investigation) do
    %{
      text:
        "Discontinued interview on #{format_date(contact_investigation.interview_discontinued_at)}: #{contact_investigation.interview_discontinue_reason}",
      link:
        link_if_editable(
          contact_investigation.exposed_person,
          :discontinue_interview
        )
    }
  end

  defp link_if_editable(person, link) do
    if PeoplePresenter.is_editable?(person) do
      link
    else
      []
    end
  end

  attr :contact_investigation, :any, required: true

  def quarantine_history_items(assigns) do
    ~H"""
    <div class="contact-investigation-history">
      <%= for item <- to_quarantine_history_items_list(@contact_investigation) do %>
        <div>
          <span data-role="contact-investigation-quarantine-history-item-text"><%= item.text %></span>
          <span class="history-item-link"><.quarantine_history_router_link label={item.link} contact_investigation={@contact_investigation} /></span>
        </div>
      <% end %>
    </div>
    """
  end

  attr :label, :any, required: true
  attr :contact_investigation, :any, required: true

  def quarantine_history_router_link(assigns) do
    ~H"""
    <.link
      :if={@label == :quarantine_dates_history}
      navigate={~p"/contact-investigations/#{@contact_investigation}/quarantine-monitoring"}
      data-role="edit-contact-investigation-quarantine-monitoring-link"
      class="contact-investigation-link"
    >
      Edit
    </.link>

    <.link
      :if={@label == :quarantine_conclusion}
      navigate={~p"/contact-investigations/#{@contact_investigation}/conclude-quarantine-monitoring"}
      data-role="conclude-contact-investigation-quarantine-monitoring-edit-link"
      class="contact-investigation-link"
    >
      Edit
    </.link>
    """
  end

  def to_quarantine_history_items_list(contact_investigation) do
    [
      quarantine_dates_history(contact_investigation),
      quarantine_conclusion(contact_investigation)
    ]
    |> Enum.filter(&Function.identity/1)
  end

  defp quarantine_dates_history(%{quarantine_monitoring_ends_on: nil, quarantine_monitoring_starts_on: nil}),
    do: nil

  defp quarantine_dates_history(contact_investigation) do
    %{
      text:
        "Quarantine dates: #{Format.date(contact_investigation.quarantine_monitoring_starts_on)} - #{Format.date(contact_investigation.quarantine_monitoring_ends_on)}",
      link:
        link_if_editable(
          contact_investigation.exposed_person,
          :quarantine_dates_history
        )
    }
  end

  defp quarantine_conclusion(%{quarantine_concluded_at: nil}), do: nil

  defp quarantine_conclusion(contact_investigation) do
    %{
      text:
        "Concluded quarantine monitoring on #{Format.date(contact_investigation.quarantine_concluded_at)}: #{Gettext.gettext(Epicenter.Gettext, contact_investigation.quarantine_conclusion_reason)}",
      link:
        link_if_editable(
          contact_investigation.exposed_person,
          :quarantine_conclusion
        )
    }
  end

  defp format_date(date),
    do: date |> Format.date_time_with_presented_time_zone()

  defp with_interviewee_name(%ContactInvestigation{interview_proxy_name: nil} = contact_investigation),
    do:
      contact_investigation
      |> ContactInvestigations.preload_exposed_person()
      |> Map.get(:exposed_person)
      |> Cases.preload_demographics()
      |> Format.person()

  defp with_interviewee_name(%ContactInvestigation{interview_proxy_name: interview_proxy_name}),
    do: "proxy #{interview_proxy_name}"
end
