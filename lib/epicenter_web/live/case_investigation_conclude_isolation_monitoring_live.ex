defmodule EpicenterWeb.CaseInvestigationConcludeIsolationMonitoringLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, authenticate_user: 2, ok: 1]

  def mount(%{"id" => _case_investigation_id}, session, socket),
    do: socket |> assign_page_title(" Case Investigation Conclude Isolation Monitoring") |> authenticate_user(session) |> ok()

  # # #
end
