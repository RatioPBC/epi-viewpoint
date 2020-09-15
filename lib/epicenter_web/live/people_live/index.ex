defmodule EpicenterWeb.PeopleLive.Index do
  use EpicenterWeb, :live_view

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Import.ImportInfo
  alias Epicenter.Cases.Person
  alias Epicenter.Extra
  alias EpicenterWeb.Session

  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Cases.subscribe()

    socket |> set_reload_message(nil) |> set_filter(:with_lab_results) |> load_people() |> load_users() |> set_selected() |> ok()
  end

  def handle_params(%{"filter" => filter}, _url, socket) when filter in ~w{call_list contacts with_lab_results},
    do: socket |> set_filter(filter) |> noreply()

  def handle_params(_, _url, socket),
    do: socket |> noreply()

  def handle_info({:assign_users, updated_people}, socket),
    do: socket |> set_selected() |> refresh_people(updated_people) |> noreply()

  def handle_info({:import, %ImportInfo{imported_person_count: imported_person_count}}, socket),
    do: socket |> set_reload_message("Show #{imported_person_count} new people") |> noreply()

  def handle_event("refresh-people", _, socket),
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
        originator: Session.get_current_user()
      )

    Cases.broadcast({:assign_users, updated_people})

    socket |> set_selected() |> refresh_people(updated_people) |> noreply()
  end

  def handle_event("form-change", _, socket),
    do: socket |> noreply()

  # # # View helpers

  def assigned_to_name(%Person{assigned_to: nil}),
    do: ""

  def assigned_to_name(%Person{assigned_to: assignee}),
    do: assignee.username

  def full_name(person),
    do: [person.first_name, person.last_name] |> Euclid.Exists.filter() |> Enum.join(" ")

  def is_disabled?(selected_people),
    do: selected_people == %{}

  def is_selected?(selected_people, %Person{id: person_id}),
    do: Map.has_key?(selected_people, person_id)

  def latest_result(person) do
    result = Person.latest_lab_result(person, :result)

    if result do
      days_ago =
        Person.latest_lab_result(person, :sampled_on)
        |> Extra.Date.days_ago()
        |> Extra.String.pluralize("day ago", "days ago")

      "#{result}, #{days_ago}"
    else
      ""
    end
  end

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

  defp noreply(socket),
    do: {:noreply, socket}

  defp ok(socket),
    do: {:ok, socket}

  defp refresh_people(socket, updated_people) do
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
