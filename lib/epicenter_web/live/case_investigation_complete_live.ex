defmodule EpicenterWeb.CaseInvestigationCompleteLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [ok: 1]

  def mount(%{"id" => _case_investigation_id}, _session, socket) do
    socket
    |> ok()
  end
end
