defmodule EpicenterWeb.Presenters.CaseInvestigationPresenter do
  import PhoenixHTMLHelpers.Tag
  use Phoenix.Component
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.Cases.Person
  alias EpicenterWeb.Format
  alias EpicenterWeb.Presenters.PeoplePresenter
  alias EpicenterWeb.Router.Helpers, as: Routes
  use Phoenix.VerifiedRoutes, endpoint: EpicenterWeb.Endpoint, router: EpicenterWeb.Router

  def contact_details_as_list(%ContactInvestigation{} = contact_investigation) do
    content_tag :ul do
      build_details_list(contact_investigation) |> Enum.map(&content_tag(:li, &1))
    end
  end

  def displayable_isolation_monitoring_status(case_investigation, current_date) do
    case case_investigation.isolation_monitoring_status do
      "pending" ->
        styled_status("Pending", :pending, :isolation_monitoring)

      "ongoing" ->
        diff = Date.diff(case_investigation.isolation_monitoring_ends_on, current_date)
        styled_status("Ongoing", :ongoing, :isolation_monitoring, "(#{diff} days remaining)")

      "concluded" ->
        styled_status("Concluded", :concluded, :isolation_monitoring)
    end
  end

  def displayable_interview_status(%{interview_status: status} = _case_investigation) do
    case status do
      "pending" -> styled_status("Pending", :pending, :interview)
      "started" -> styled_status("Ongoing", :started, :interview)
      "completed" -> styled_status("Completed", "completed-interview", :interview)
      _ -> [content_tag(:span, "Discontinued", class: :discontinued)]
    end
  end

  attr :person, :any, required: true
  attr :case_investigation, :any, required: true

  def history_items(assigns) do
    ~H"""
    <div class="case-investigation-history">
      <%= for item <- to_history_items_list(@person, @case_investigation) do %>
        <div>
          <span data-role="case-investigation-history-item-text"><%= item.text %></span>
          <span class="history-item-link">
            <.case_investigation_router_link
              label={item.link}
              case_investigation={@case_investigation}/>
          </span>
        </div>
      <% end %>
    </div>
    """
  end

  attr :label, :any, required: true
  attr :case_investigation, :any, required: true

  def case_investigation_router_link(assigns) do
    ~H"""
    <.link
      :if={@label == :started_interview}
      navigate={Routes.case_investigation_start_interview_path(
                      EpicenterWeb.Endpoint,
                      EpicenterWeb.CaseInvestigationStartInterviewLive,
                      @case_investigation
                    )}
      class="case-investigation-link"
    >Edit</.link>
    <.link
      :if={@label == :discontinued_interview}
      navigate={Routes.case_investigation_discontinue_path(
                      EpicenterWeb.Endpoint,
                      EpicenterWeb.CaseInvestigationDiscontinueLive,
                      @case_investigation
                    )}
      id="edit-discontinue-case-investigation-link-001"
      class="discontinue-case-investigation-link"
    >Edit</.link>
    <.link
      :if={@label == :completed_interview}
      navigate={Routes.case_investigation_complete_interview_path(
                      EpicenterWeb.Endpoint,
                      :complete_case_investigation,
                      @case_investigation
                    )}
      id="edit-complete-interview-link-001"
      class="edit-complete-interview-link"
    >Edit</.link>
    """
  end

  defp to_history_items_list(person, case_investigation) do
    items = []

    items =
      if case_investigation.interview_started_at do
        [
          %{
            text: "Started interview with #{with_interviewee_name(case_investigation)} on #{interview_start_date(case_investigation)}",
            link: link_if_editable(person, :started_interview)
          }
          | items
        ]
      else
        items
      end

    items =
      if case_investigation.interview_discontinue_reason != nil do
        [
          %{
            text:
              "Discontinued interview on #{case_investigation.interview_discontinued_at |> Format.date_time_with_presented_time_zone()}: #{case_investigation.interview_discontinue_reason}",
            link: link_if_editable(person, :discontinued_interview)
          }
          | items
        ]
      else
        items
      end

    items =
      if case_investigation.interview_completed_at != nil do
        [
          %{
            text: "Completed interview on #{completed_interview_date(case_investigation)}",
            link: link_if_editable(person, :completed_interview)
          }
          | items
        ]
      else
        items
      end

    items |> Enum.reverse()
  end

  attr :person, :any, required: true
  attr :case_investigation, :any, required: true

  def interview_buttons(assigns) do
    ~H"""
      <div class="case-investigation-interview-buttons">
        <%= for link <- to_interview_buttons_list(@person, @case_investigation) do %>
          <span>
            <.interview_buttons_router_link
              label={link}
              case_investigation={@case_investigation}/>
          </span>
        <% end %>
      </div>
    """
  end

  attr :label, :any, required: true
  attr :case_investigation, :any, required: true

  def interview_buttons_router_link(assigns) do
    ~H"""
    <.link
      :if={@label == :start_interview}
      navigate={Routes.case_investigation_start_interview_path(
                  EpicenterWeb.Endpoint,
                  EpicenterWeb.CaseInvestigationStartInterviewLive,
                  @case_investigation
                )}
      id="start-interview-case-investigation-link-001"
      class="primary"
    >Start interview</.link>
    <.link
      :if={@label == :complete_interview}
      navigate={Routes.case_investigation_complete_interview_path(
                  EpicenterWeb.Endpoint,
                  :complete_case_investigation,
                  @case_investigation
                )}
      id="complete-interview-case-investigation-link-001"
      class="primary"
    >Complete interview</.link>
    <.link
      :if={@label == :discontinue_interview}
      navigate={Routes.case_investigation_discontinue_path(
                  EpicenterWeb.Endpoint,
                  EpicenterWeb.CaseInvestigationDiscontinueLive,
                  @case_investigation
                )}
      id="discontinue-case-investigation-link-001"
      class="discontinue-case-investigation-link"
    >Discontinue</.link>
    """
  end

  defp to_interview_buttons_list(person, case_investigation) do
    if PeoplePresenter.is_editable?(person) do
      case case_investigation.interview_status do
        "pending" ->
          [:start_interview, :discontinue_interview]

        "started" ->
          [:complete_interview, :discontinue_interview]

        "completed" ->
          []

        "discontinued" ->
          []
      end
    else
      []
    end
  end

  attr :case_investigation, :any, required: true

  def isolation_monitoring_button(assigns) do
    ~H"""
      <.link
        :if={@case_investigation.isolation_monitoring_status == "pending"}
        navigate={Routes.case_investigation_isolation_monitoring_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationIsolationMonitoringLive,
                    @case_investigation
                  )}
        id="add-isolation-dates-case-investigation-link-001"
        class="primary"
      >Add isolation dates</.link>
      <.link
        :if={@case_investigation.isolation_monitoring_status == "ongoing"}
        navigate={Routes.case_investigation_conclude_isolation_monitoring_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationConcludeIsolationMonitoringLive,
                    @case_investigation
                  )}
        id="conclude-isolation-monitoring-case-investigation-link-001"
        class="primary"
      >Conclude isolation</.link>
    """
  end

  attr :person, :any, required: true
  attr :case_investigation, :any, required: true

  def isolation_monitoring_history_items(assigns) do
    ~H"""
    <div class="case-investigation-history">
      <%= for item <- to_isolation_monitoring_history_items_list(@person, @case_investigation) do %>
        <div>
          <span data-role="isolation-monitoring-history-item-text"><%= item.text %></span>
          <span class="history-item-link">
            <.isolation_monitoring_history_items_router_link
              label={item.link}
              case_investigation={@case_investigation}/>
          </span>
        </div>
      <% end %>
    </div>
    """
  end

  attr :label, :any, required: true
  attr :case_investigation, :any, required: true

  def isolation_monitoring_history_items_router_link(assigns) do
    ~H"""
    <.link
      :if={@label == :edit_isolation_monitoring}
      navigate={Routes.case_investigation_isolation_monitoring_path(
                  EpicenterWeb.Endpoint,
                  EpicenterWeb.CaseInvestigationIsolationMonitoringLive,
                  @case_investigation
                )}
      id="edit-isolation-monitoring-link-001"
      class="case-investigation-link"
    >Edit</.link>
    <.link
      :if={@label == :edit_isolation_monitoring_conclusion}
      navigate={Routes.case_investigation_conclude_isolation_monitoring_path(
                  EpicenterWeb.Endpoint,
                  EpicenterWeb.CaseInvestigationConcludeIsolationMonitoringLive,
                  @case_investigation
                )}
      id="edit-isolation-monitoring-conclusion-link-001"
      class="case-investigation-link"
    >Edit</.link>
    """
  end

  defp to_isolation_monitoring_history_items_list(person, case_investigation) do
    items = []

    items =
      if case_investigation.isolation_monitoring_starts_on do
        [
          %{
            text:
              "Isolation dates: #{Format.date(case_investigation.isolation_monitoring_starts_on)} - #{Format.date(case_investigation.isolation_monitoring_ends_on)}",
            link: link_if_editable(person, :edit_isolation_monitoring)
          }
          | items
        ]
      else
        items
      end

    items =
      if case_investigation.isolation_concluded_at do
        [
          %{
            text:
              "Concluded isolation monitoring on #{concluded_isolation_monitoring_date(case_investigation)}. #{Gettext.gettext(Epicenter.Gettext, case_investigation.isolation_conclusion_reason)}",
            link: link_if_editable(person, :edit_isolation_monitoring_conclusion)
          }
          | items
        ]
      else
        items
      end

    items |> Enum.reverse()
  end

  def symptoms_options() do
    [
      {"Fever > 100.4F", "fever"},
      {"Subjective fever (felt feverish)", "subjective_fever"},
      {"Cough", "cough"},
      {"Shortness of breath", "shortness_of_breath"},
      {"Diarrhea/GI", "diarrhea_gi"},
      {"Headache", "headache"},
      {"Muscle ache", "muscle_ache"},
      {"Chills", "chills"},
      {"Sore throat", "sore_throat"},
      {"Vomiting", "vomiting"},
      {"Abdominal pain", "abdominal_pain"},
      {"Nasal congestion", "nasal_congestion"},
      {"Loss of sense of smell", "loss_of_sense_of_smell"},
      {"Loss of sense of taste", "loss_of_sense_of_taste"},
      {"Fatigue", "fatigue"},
      {"Other", "Other"}
    ]
  end

  def displayable_status(nil, _),
    do: ""

  def displayable_status(%CaseInvestigation{} = investigation, current_date) do
    displayable_status(
      investigation.interview_status,
      investigation.isolation_monitoring_status,
      investigation.isolation_monitoring_ends_on,
      current_date
    )
  end

  def displayable_status(%ContactInvestigation{} = investigation, current_date) do
    displayable_status(
      investigation.interview_status,
      investigation.quarantine_monitoring_status,
      investigation.quarantine_monitoring_ends_on,
      current_date
    )
  end

  def displayable_status(interview_status, monitoring_status, monitoring_ends_on, current_date) do
    case interview_status do
      "pending" ->
        "Pending interview"

      "started" ->
        "Ongoing interview"

      "completed" ->
        case monitoring_status do
          "pending" ->
            "Pending monitoring"

          "ongoing" ->
            diff = Date.diff(monitoring_ends_on, current_date)
            "Ongoing monitoring (#{diff} days remaining)"

          "concluded" ->
            "Concluded monitoring"
        end

      "discontinued" ->
        "Discontinued"
    end
  end

  # # #

  defp build_details_list(%{
         guardian_name: guardian_name,
         guardian_phone: guardian_phone,
         relationship_to_case: relationship_to_case,
         most_recent_date_together: most_recent_date_together,
         household_member: household_member,
         under_18: under_18,
         exposed_person: exposed_person
       }) do
    demographic = Person.coalesce_demographics(exposed_person)
    phones = exposed_person.phones |> Enum.map(fn phone -> Format.phone(phone) end)

    details = [relationship_to_case]
    details = if household_member, do: details ++ ["Household"], else: details

    details =
      if under_18 do
        details = details ++ ["Minor"]
        details = details ++ ["Guardian: #{guardian_name}"]
        details = if Euclid.Exists.present?(guardian_phone), do: details ++ [Format.phone(guardian_phone)], else: details
        details
      else
        details ++ phones
      end

    details = if Euclid.Exists.present?(demographic.preferred_language), do: details ++ [demographic.preferred_language], else: details
    details ++ ["Last together #{Format.date(most_recent_date_together)}"]
  end

  defp completed_interview_date(case_investigation),
    do: case_investigation.interview_completed_at |> Format.date_time_with_presented_time_zone()

  defp concluded_isolation_monitoring_date(case_investigation),
    do: case_investigation.isolation_concluded_at |> Format.date_time_with_presented_time_zone()

  defp interview_start_date(case_investigation),
    do: case_investigation.interview_started_at |> Format.date_time_with_presented_time_zone()

  defp link_if_editable(person, link) do
    if PeoplePresenter.is_editable?(person) do
      link
    else
      []
    end
  end

  defp styled_status(displayable_status, status, type, postscript \\ "") when type in [:interview, :isolation_monitoring] do
    type_string = %{interview: "interview", isolation_monitoring: "isolation monitoring"}[type]

    content_tag :span do
      [content_tag(:span, displayable_status, class: status), " #{type_string} #{postscript}"]
    end
  end

  defp with_interviewee_name(%CaseInvestigation{interview_proxy_name: nil} = case_investigation),
    do: case_investigation |> Cases.preload_person() |> Map.get(:person) |> Cases.preload_demographics() |> Format.person()

  defp with_interviewee_name(%CaseInvestigation{interview_proxy_name: interview_proxy_name}),
    do: "proxy #{interview_proxy_name}"
end
