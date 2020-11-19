defmodule EpicenterWeb.PeopleFilter do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  def render(assigns) do
    checked = if(assigns.display_people_assigned_to_me, do: "checked", else: "")

    ~L"""
    <%= live_patch "All", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :with_positive_lab_results), class: "button", data: [active: assigns.filter in [:with_positive_lab_results, nil], role: "people-filter", tid: "all"] %>
    <%= live_patch "Pending interview", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :with_pending_interview), class: "button", data: [active: assigns.filter == :with_pending_interview, role: "people-filter", tid: "with_pending_interview"] %>
    <label id="assigned-to-me-button">
      <input type="checkbox" phx-click="toggle-assigned-to-me" <%= checked %> data-tid="assigned-to-me-checkbox" phx-target="<%= @myself %>">
      <span>My Assignments Only</span>
    </label>
    """
  end

  def handle_event("toggle-assigned-to-me", _, socket) do
    socket = socket |> assign(:display_people_assigned_to_me, !socket.assigns.display_people_assigned_to_me)
    socket.assigns.on_toggle_assigned_to_me.(socket.assigns.display_people_assigned_to_me)
    socket |> noreply()
  end
end

defmodule EpicenterWeb.PeopleLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]
  import EpicenterWeb.LiveComponent.Helpers

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Person
  alias Epicenter.Extra
  alias EpicenterWeb.PeopleFilter

  @clock Application.get_env(:epicenter, :clock)

  def mount(_params, session, socket) do
    if connected?(socket),
      do: Cases.subscribe_to_people()

    socket
    |> authenticate_user(session)
    |> assign_page_title("People")
    |> assign_current_date()
    |> assign_reload_message(nil)
    |> assign(:display_people_assigned_to_me, false)
    |> assign_filter(:with_positive_lab_results)
    |> load_and_assign_people()
    |> load_and_assign_users()
    |> assign_selected_to_empty()
    |> ok()
  end

  def handle_event("checkbox-click", %{"value" => "on", "person-id" => person_id} = _value, socket),
    do: socket |> select_person(person_id) |> noreply()

  def handle_event("checkbox-click", %{"person-id" => person_id} = _value, socket),
    do: socket |> deselect_person(person_id) |> noreply()

  def handle_event("form-change", %{"user" => "-unassigned-"}, socket),
    do: handle_event("form-change", %{"user" => nil}, socket)

  def handle_event("form-change", %{"user" => user_id}, socket) do
    {:ok, updated_people} =
      Cases.assign_user_to_people(
        user_id: user_id,
        people_ids:
          socket.assigns.people
          |> Enum.filter(fn person -> Map.get(socket.assigns.selected_people, person.id) end)
          |> Euclid.Extra.Enum.pluck(:id),
        audit_meta: %AuditLog.Meta{
          author_id: socket.assigns.current_user.id,
          reason_action: AuditLog.Revision.update_assignment_bulk_action(),
          reason_event: AuditLog.Revision.people_selected_assignee_event()
        }
      )

    Cases.broadcast_people(updated_people)

    socket |> assign_selected_to_empty() |> refresh_existing_people(updated_people) |> noreply()
  end

  def handle_event("form-change", _, socket),
    do: socket |> noreply()

  def handle_event("reload-people", _, socket),
    do: socket |> assign_reload_message(nil) |> load_and_assign_people() |> noreply()

  def handle_info({:display_people_assigned_to_me_toggled, display_people_assigned_to_me}, socket) do
    socket
    |> assign(:display_people_assigned_to_me, display_people_assigned_to_me)
    |> load_and_assign_people()
    |> noreply()
  end

  def handle_info({:people, updated_people}, socket),
    do: socket |> assign_selected_to_empty() |> refresh_existing_people(updated_people) |> prompt_to_reload(updated_people) |> noreply()

  def handle_params(%{"filter" => filter}, _url, socket) when filter in ~w{with_pending_interview with_positive_lab_results} do
    socket |> assign_filter(filter) |> load_and_assign_people() |> noreply()
  end

  def handle_params(_, _url, socket),
    do: socket |> noreply()

  def on_toggle_assigned_to_me(display_people_assigned_to_me) do
    send(self(), {:display_people_assigned_to_me_toggled, display_people_assigned_to_me})
  end

  # # # View helpers

  def assigned_to_name(%Person{assigned_to: nil}),
    do: ""

  def assigned_to_name(%Person{assigned_to: assignee}),
    do: assignee.name

  def disabled?(selected_people),
    do: selected_people == %{}

  def external_id(person),
    do: Person.coalesce_demographics(person).external_id

  def full_name(person) do
    demographic = Person.coalesce_demographics(person)
    [demographic.first_name, demographic.last_name] |> Euclid.Exists.filter() |> Enum.join(" ")
  end

  def latest_case_investigation_status(person, current_date),
    do: person |> Person.latest_case_investigation() |> displayable_status(current_date)

  def latest_result(person) do
    lab_result = Person.latest_lab_result(person)

    if lab_result do
      result = lab_result.result || "unknown"

      "#{result}, #{days_ago(lab_result)}"
    else
      ""
    end
  end

  def page_title(:call_list), do: "Call List"
  def page_title(:contacts), do: "Contacts"
  def page_title(:with_pending_interview), do: "Pending interviews"
  def page_title(:with_positive_lab_results), do: "Index Cases"

  def selected?(selected_people, %Person{id: person_id}),
    do: Map.has_key?(selected_people, person_id)

  # # # Private

  def assign_current_date(socket) do
    timezone = EpicenterWeb.PresentationConstants.presented_time_zone()
    current_date = @clock.utc_now() |> DateTime.shift_zone!(timezone) |> DateTime.to_date()
    socket |> assign(current_date: current_date)
  end

  defp assign_people(socket, people),
    do: assign(socket, people: people, person_count: length(people))

  defp days_ago(%{sampled_on: nil} = _lab_result), do: "unknown date"
  defp days_ago(%{sampled_on: sampled_on} = _lab_result), do: sampled_on |> Extra.Date.days_ago_string()

  defp displayable_status(nil, _),
    do: ""

  defp displayable_status(case_investigation, current_date) do
    case CaseInvestigation.status(case_investigation) do
      :pending ->
        "Pending interview"

      :started ->
        "Ongoing interview"

      :completed_interview ->
        case CaseInvestigation.isolation_monitoring_status(case_investigation) do
          :pending ->
            "Pending monitoring"

          :ongoing ->
            diff = Date.diff(case_investigation.isolation_monitoring_end_date, current_date)
            "Ongoing monitoring (#{diff} days remaining)"

          :concluded ->
            "Concluded monitoring"
        end

      :discontinued ->
        "Discontinued"
    end
  end

  defp deselect_person(%{assigns: %{selected_people: selected_people}} = socket, person_id),
    do: assign(socket, selected_people: Map.delete(selected_people, person_id))

  defp load_and_assign_people(socket) do
    people =
      cond do
        socket.assigns.display_people_assigned_to_me ->
          Cases.list_people(socket.assigns.filter, assigned_to_id: socket.assigns.current_user.id)

        true ->
          Cases.list_people(socket.assigns.filter)
      end
      |> Cases.preload_lab_results()
      |> Cases.preload_assigned_to()
      |> Cases.preload_demographics()
      |> Cases.preload_case_investigations()

    assign_people(socket, people)
  end

  defp load_and_assign_users(socket),
    do: socket |> assign(users: Accounts.list_users())

  defp prompt_to_reload(socket, _people) do
    assign_reload_message(socket, "An import was completed. Show new people.")
  end

  defp refresh_existing_people(socket, updated_people) do
    id_to_people_map = updated_people |> Enum.reduce(%{}, fn person, acc -> acc |> Map.put(person.id, person) end)
    refreshed_people = socket.assigns.people |> Enum.map(fn person -> Map.get(id_to_people_map, person.id, person) end)
    assign_people(socket, refreshed_people)
  end

  defp select_person(%{assigns: %{selected_people: selected_people}} = socket, person_id),
    do: assign(socket, selected_people: Map.put(selected_people, person_id, true))

  defp assign_filter(socket, filter) when is_binary(filter),
    do: socket |> assign_filter(Euclid.Extra.Atom.from_string(filter))

  defp assign_filter(socket, filter) when is_atom(filter),
    do: socket |> assign(filter: filter, page_title: page_title(filter))

  defp assign_reload_message(socket, message),
    do: socket |> assign(reload_message: message)

  defp assign_selected_to_empty(socket),
    do: socket |> assign(selected_people: %{})
end
