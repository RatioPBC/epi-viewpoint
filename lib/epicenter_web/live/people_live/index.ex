defmodule EpicenterWeb.PeopleLive.Index do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias Epicenter.Cases.Import.ImportInfo
  alias Epicenter.Cases.Person
  alias Epicenter.Extra

  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Cases.subscribe()

    socket |> set_reload_message(nil) |> set_filter(:with_lab_results) |> load_people() |> ok()
  end

  def handle_params(%{"filter" => filter}, _url, socket) when filter in ~w{call_list contacts with_lab_results},
    do: socket |> set_filter(filter) |> noreply()

  def handle_params(_, _url, socket),
    do: socket |> noreply()

  def handle_info({:import, %ImportInfo{imported_person_count: imported_person_count}}, socket),
    do: socket |> set_reload_message("Show #{imported_person_count} new people") |> noreply()

  def handle_event("refresh-people", _, socket),
    do: socket |> set_reload_message(nil) |> load_people() |> noreply()

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
        Person.latest_lab_result(person, :sample_date)
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

  def page_title(:call_list), do: "Call List"
  def page_title(:contacts), do: "Contacts"
  def page_title(:with_lab_results), do: "People"
end
