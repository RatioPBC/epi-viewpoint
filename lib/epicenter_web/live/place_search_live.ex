defmodule EpicenterWeb.PlaceSearchLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, ok: 1]

  alias Epicenter.Cases

  def mount(params, session, socket) do
    socket = socket |> authenticate_user(session)

    case_investigation = Cases.get_case_investigation(params["id"], socket.assigns.current_user)

    socket
    |> assign_defaults()
    |> assign_page_title("Add place visited")
    |> assign(:case_investigation, case_investigation)
    |> ok()
  end
end
