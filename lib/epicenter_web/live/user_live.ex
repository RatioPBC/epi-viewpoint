defmodule EpicenterWeb.UserLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_admin_user!: 2, assign_page_title: 2, ok: 1]

  def mount(_params, session, socket) do
    socket
    |> authenticate_admin_user!(session)
    |> assign_page_title("User")
    |> ok()
  end
end
