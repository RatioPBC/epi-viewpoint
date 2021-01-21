defmodule EpicenterWeb.ResolveConflictsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, authenticate_user: 2, ok: 1]

  def mount(_, session, socket) do
    socket = socket |> authenticate_user(session)

    socket
    |> assign_defaults(body_class: "body-background-none")
    |> assign_page_title("Resolve Conflicts")
    |> ok()
  end
end
