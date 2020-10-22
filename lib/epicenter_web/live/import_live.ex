defmodule EpicenterWeb.ImportLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, ok: 1]

  def mount(_params, session, socket) do
    socket
    |> authenticate_user(session)
    |> assign_page_title("Import labs")
    |> assign(:import_error_message, session["import_error_message"])
    |> assign(uploading: false)
    |> ok()
  end
end
