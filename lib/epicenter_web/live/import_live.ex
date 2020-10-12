defmodule EpicenterWeb.ImportLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, ok: 1]

  def mount(_params, session, socket) do
    socket
    |> assign_defaults(session)
    |> assign_page_title("Import labs")
    |> assign(:import_error_message, session["import_error_message"])
    |> assign(uploading: false)
    |> ok()
  end
end
