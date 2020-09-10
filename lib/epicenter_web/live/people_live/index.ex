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

  def handle_info({:import, %ImportInfo{imported_person_count: imported_person_count}}, socket),
    do: socket |> set_reload_message("Show #{imported_person_count} new people") |> noreply()

  def handle_event("refresh-people", _, socket),
    do: socket |> set_reload_message(nil) |> load_people() |> noreply()

  def handle_event("checkbox-click", %{"value" => "on", "person-id" => person_id} = _value, socket) do
    socket |> select_person(person_id) |> noreply()
  end

  def handle_event("checkbox-click", %{"person-id" => person_id} = _value, socket),
    do: socket |> deselect_person(person_id) |> noreply()

  def handle_event("form-save", value, socket) do
    people_ids = socket.assigns.selected_people |> Map.keys()
    selected_user_id = Map.get(value, "user")

    Cases.assign_user_to_people(user_id: selected_user_id, people_ids: people_ids, originator: Session.get_current_user())

    socket |> noreply()
  end

  defp set_selected(socket) do
    socket |> assign(selected_people: %{})
  end

  defp select_person(%{assigns: %{selected_people: selected_people}} = socket, person_id) do
    assign(socket, selected_people: Map.put(selected_people, person_id, true))
  end

  defp deselect_person(%{assigns: %{selected_people: selected_people}} = socket, person_id) do
    assign(socket, selected_people: Map.delete(selected_people, person_id))
  end

  defp set_filter(socket, filter) when is_binary(filter),
    do: socket |> set_filter(Euclid.Extra.Atom.from_string(filter))

  defp set_filter(socket, filter) when is_atom(filter),
    do: socket |> assign(filter: filter, page_title: page_title(filter)) |> load_people()

  defp set_reload_message(socket, message),
    do: socket |> assign(reload_message: message)

  # # #

  defp ok(socket),
    do: {:ok, socket}

  defp noreply(socket),
    do: {:noreply, socket}

  # # #

  def full_name(person),
    do: [person.first_name, person.last_name] |> Euclid.Exists.filter() |> Enum.join(" ")

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

  defp load_people(socket) do
    people = Cases.list_people(socket.assigns.filter) |> Cases.preload_lab_results()
    socket |> assign(people: people, person_count: length(people))
  end

  defp load_users(socket) do
    users = Accounts.list_users()
    socket |> assign(users: users)
  end

  def page_title(:call_list), do: "Call List"
  def page_title(:contacts), do: "Contacts"
  def page_title(:with_lab_results), do: "People"
end
