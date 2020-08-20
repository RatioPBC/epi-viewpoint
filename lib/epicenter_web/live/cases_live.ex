defmodule EpicenterWeb.CasesLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias Epicenter.Cases.Import.ImportInfo

  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Cases.subscribe()

    cases = Cases.list_cases()

    {:ok, assign(socket, cases: cases, case_count: length(cases), reload_message: nil)}
  end

  def handle_info({:import, %ImportInfo{imported_person_count: imported_person_count}}, socket) do
    socket = assign(socket, reload_message: "Show #{imported_person_count} new cases")

    {:noreply, socket}
  end

  def handle_event("refresh-cases", _, socket) do
    cases = Cases.list_cases()
    socket = assign(socket, cases: cases, case_count: length(cases), reload_message: nil)
    {:noreply, socket}
  end
end
