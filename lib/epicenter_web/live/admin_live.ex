defmodule EpicenterWeb.AdminLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias Epicenter.Cases.Import.ImportInfo

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Epicenter.PubSub, "cases")
    end

    {:ok, assign(socket, person_count: Cases.count_people(), lab_result_count: Cases.count_lab_results())}
  end

  def handle_info({:import, %ImportInfo{total_person_count: person_count, total_lab_result_count: lab_result_count}}, socket) do
    socket = assign(socket, person_count: person_count, lab_result_count: lab_result_count)
    {:noreply, socket}
  end
end
