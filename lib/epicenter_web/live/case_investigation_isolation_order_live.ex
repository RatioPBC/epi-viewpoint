defmodule EpicenterWeb.CaseInvestigationIsolationOrderLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, ok: 1]

  def mount(%{"id" => _case_investigation_id}, session, socket) do
    socket
    |> authenticate_user(session)
    |> ok()
  end
end
