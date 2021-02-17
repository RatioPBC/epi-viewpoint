defmodule EpicenterWeb.VisitLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, ok: 1]

  def mount(_params, session, socket) do
    socket = socket |> authenticate_user(session)

    socket
    |> assign_defaults()
    |> assign_page_title("New visit")
    |> ok()
  end
end
