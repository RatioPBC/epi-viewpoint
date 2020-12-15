defmodule EpicenterWeb.ContactInvestigationClinicalDetailsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, ok: 1]

  def mount(%{"id" => _id}, session, socket) do
    socket
    |> authenticate_user(session)
    |> assign_page_title(" Contact Investigation Clinical Details")
    |> ok()
  end
end
