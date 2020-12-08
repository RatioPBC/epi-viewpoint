defmodule EpicenterWeb.ContactInvestigationStartInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, authenticate_user: 2, ok: 1]

  def mount(%{"exposure_id" => _case_investigation_id}, session, socket) do
    socket = socket |> authenticate_user(session)

    socket
    |> assign_page_title("Start Contact Investigation -- Coming soon")
    |> ok()
  end
end
