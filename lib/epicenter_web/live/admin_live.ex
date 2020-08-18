defmodule EpicenterWeb.AdminLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases

  def mount(_params, _session, socket) do
    {:ok, assign(socket, person_count: Cases.count_people(), lab_result_count: Cases.count_lab_results())}
  end
end
