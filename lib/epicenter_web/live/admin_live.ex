defmodule EpicenterWeb.AdminLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases

  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Cases.subscribe_to_people()

    {:ok, assign_counts(socket)}
  end

  def handle_info({:people, _people}, socket) do
    {:noreply, assign_counts(socket)}
  end

  defp assign_counts(socket) do
    assign(socket, person_count: Cases.count_people(), lab_result_count: Cases.count_lab_results())
  end
end
