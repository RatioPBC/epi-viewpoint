defmodule EpicenterWeb.PeopleLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Extra

  def mount(_params, session, socket) do
    if connected?(socket),
      do: Cases.subscribe_to_people()

    socket
    |> assign_defaults(session)
    |> assign_page_title("People")
    |> set_reload_message(nil)
    |> set_filter(:with_lab_results)
    |> load_people()
    |> load_users()
    |> set_selected()
    |> ok()
  end

  def handle_params(%{"filter" => filter}, _url, socket) when filter in ~w{call_list contacts with_lab_results},
    do: socket |> set_filter(filter) |> noreply()

  def handle_params(_, _url, socket),
    do: socket |> noreply()

  def handle_info({:people, updated_people}, socket),
    do: socket |> set_selected() |> refresh_existing_people(updated_people) |> maybe_prompt_to_reload(updated_people) |> noreply()

  def handle_event("reload-people", _, socket),
    do: socket |> set_reload_message(nil) |> load_people() |> noreply()

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
        people_ids: Map.keys(socket.assigns.selected_people),
        audit_meta: %AuditLog.Meta{
          author_id: socket.assigns.current_user.id,
          reason_action: AuditLog.Revision.update_assignment_bulk_action(),
          reason_event: AuditLog.Revision.people_selected_assignee_event()
        }
      )

    Cases.broadcast_people(updated_people)

    socket |> set_selected() |> refresh_existing_people(updated_people) |> noreply()
  end

  def handle_event("form-change", _, socket),
    do: socket |> noreply()

  # # # View helpers

  def assigned_to_name(%Person{assigned_to: nil}),
    do: ""

  def assigned_to_name(%Person{assigned_to: assignee}),
    do: assignee.name

  def full_name(person),
    do: [person.first_name, person.last_name] |> Euclid.Exists.filter() |> Enum.join(" ")

  def is_disabled?(selected_people),
    do: selected_people == %{}

  def is_selected?(selected_people, %Person{id: person_id}),
    do: Map.has_key?(selected_people, person_id)

  def latest_result(person) do
    lab_result = Person.latest_lab_result(person)

    if lab_result do
      result = lab_result.result || "unknown"

      "#{result}, #{days_ago(lab_result)}"
    else
      ""
    end
  end

  defp days_ago(%{sampled_on: nil} = _lab_result), do: "unknown date"
  defp days_ago(%{sampled_on: sampled_on} = _lab_result), do: sampled_on |> Extra.Date.days_ago_string()

  def page_title(:call_list), do: "Call List"
  def page_title(:contacts), do: "Contacts"
  def page_title(:with_lab_results), do: "People"

  # # # Private

  defp assign_people(socket, people),
    do: assign(socket, people: people, person_count: length(people))

  defp deselect_person(%{assigns: %{selected_people: selected_people}} = socket, person_id),
    do: assign(socket, selected_people: Map.delete(selected_people, person_id))

  defp load_people(socket) do
    people = Cases.list_people(socket.assigns.filter) |> Cases.preload_lab_results() |> Cases.preload_assigned_to()
    assign_people(socket, people)
  end

  defp load_users(socket),
    do: socket |> assign(users: Accounts.list_users())

  defp maybe_prompt_to_reload(socket, people) do
    existing_people_ids = socket.assigns.people |> Euclid.Extra.Enum.pluck(:id) |> MapSet.new()
    new_people_ids = people |> Euclid.Extra.Enum.pluck(:id) |> MapSet.new()

    if MapSet.subset?(new_people_ids, existing_people_ids) do
      socket
    else
      new_people_count = MapSet.difference(new_people_ids, existing_people_ids) |> MapSet.size()
      set_reload_message(socket, "Show #{new_people_count} new people")
    end
  end

  defp refresh_existing_people(socket, updated_people) do
    id_to_people_map = updated_people |> Enum.reduce(%{}, fn person, acc -> acc |> Map.put(person.id, person) end)
    refreshed_people = socket.assigns.people |> Enum.map(fn person -> Map.get(id_to_people_map, person.id, person) end)
    assign_people(socket, refreshed_people)
  end

  defp select_person(%{assigns: %{selected_people: selected_people}} = socket, person_id),
    do: assign(socket, selected_people: Map.put(selected_people, person_id, true))

  defp set_filter(socket, filter) when is_binary(filter),
    do: socket |> set_filter(Euclid.Extra.Atom.from_string(filter))

  defp set_filter(socket, filter) when is_atom(filter),
    do: socket |> assign(filter: filter, page_title: page_title(filter)) |> load_people()

  defp set_reload_message(socket, message),
    do: socket |> assign(reload_message: message)

  defp set_selected(socket),
    do: socket |> assign(selected_people: %{})
end
