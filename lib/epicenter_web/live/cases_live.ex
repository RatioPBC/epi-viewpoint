defmodule EpicenterWeb.CasesLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias Epicenter.Cases.Import.ImportInfo

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Epicenter.PubSub, "cases")
    end

    {:ok, assign(socket, cases: Cases.list_cases(), person_count: Cases.count_people(), reload_message: "")}
  end

  def handle_info({:import, %ImportInfo{imported_person_count: imported_person_count}}, socket) do
    socket =
      assign(socket, person_count: imported_person_count, reload_message: "#{imported_person_count} new cases have arrived. Click here to load them.")

    {:noreply, socket}
  end

  def handle_event("refresh-cases", _, socket) do
    socket = assign(socket, cases: Cases.list_cases(), reload_message: "")
    {:noreply, socket}
  end
end
