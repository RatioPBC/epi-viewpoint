defmodule EpicenterWeb.ContactInvestigationCompleteInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, ok: 1]

  def mount(%{"id" => _contact_investigation_id}, session, socket) do
    socket
    |> assign_defaults()
    |> assign_page_title("Complete interview")
    |> authenticate_user(session)
    |> ok()
  end
end
