defmodule EpicenterWeb.PeopleLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Person
  alias Epicenter.Extra

  @clock Application.get_env(:epicenter, :clock)

  def mount(_params, session, socket) do
    if connected?(socket),
      do: Cases.subscribe_to_people()

    socket
    |> authenticate_user(session)
    |> assign_page_title("People")
    |> assign_current_date()
    |> assign_reload_message(nil)
    |> assign_filter(:with_positive_lab_results)
    |> assign(:only_assigned_to_me, false)
    |> load_and_assign_people()
    |> load_and_assign_users()
    |> assign_selected_to_empty()
    |> ok()
  end

  def handle_params(%{"filter" => filter}, _url, socket) when filter in ~w{call_list contacts with_positive_lab_results},
    do: socket |> assign_filter(filter) |> noreply()

  def handle_params(_, _url, socket),
    do: socket |> noreply()

  def handle_info({:people, updated_people}, socket),
    do: socket |> assign_selected_to_empty() |> refresh_existing_people(updated_people) |> prompt_to_reload(updated_people) |> noreply()

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
          visible_people(socket.assigns[:people], socket.assigns[:only_assigned_to_me], socket.assigns[:current_user])
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

  def handle_event("toggle-assigned-to-me", _, socket),
    do: socket |> assign(:only_assigned_to_me, !socket.assigns[:only_assigned_to_me]) |> noreply()

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
  def page_title(:with_positive_lab_results), do: "Index Cases"

  def selected?(selected_people, %Person{id: person_id}),
    do: Map.has_key?(selected_people, person_id)

  def visible_people(people, only_assigned_to_me, user)

  def visible_people(people, true, user) do
    Enum.filter(people, fn person -> person.assigned_to_id == user.id end)
  end

  def visible_people(people, false, _), do: people

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
      Cases.list_people(socket.assigns.filter)
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
    do: socket |> assign(filter: filter, page_title: page_title(filter)) |> load_and_assign_people()

  defp assign_reload_message(socket, message),
    do: socket |> assign(reload_message: message)

  defp assign_selected_to_empty(socket),
    do: socket |> assign(selected_people: %{})
end
