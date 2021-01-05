defmodule EpicenterWeb.ContactInvestigationConcludeQuarantineMonitoringLive do
  use EpicenterWeb, :live_view
  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, authenticate_user: 2, ok: 1]

  def mount(_params, session, socket) do
    socket
    |> assign_defaults()
    |> authenticate_user(session)
    |> ok()
  end
end
