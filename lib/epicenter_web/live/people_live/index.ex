defmodule EpicenterWeb.PeopleLive.Index do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias Epicenter.Cases.Import.ImportInfo
  alias Epicenter.Cases.Person

  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Cases.subscribe()

    people = Cases.list_people() |> Cases.preload_lab_results()

    {:ok, assign(socket, people: people, person_count: length(people), reload_message: nil)}
  end

  def handle_info({:import, %ImportInfo{imported_person_count: imported_person_count}}, socket) do
    socket = assign(socket, reload_message: "Show #{imported_person_count} new people")

    {:noreply, socket}
  end

  def handle_event("refresh-people", _, socket) do
    people = Cases.list_people() |> Cases.preload_lab_results()
    socket = assign(socket, people: people, person_count: length(people), reload_message: nil)
    {:noreply, socket}
  end

  def latest_result(person),
    do: Person.latest_lab_result(person, :result)

  def latest_sample_date(person),
    do: Person.latest_lab_result(person, :sample_date)
end
