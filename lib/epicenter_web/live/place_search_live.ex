defmodule EpicenterWeb.PlaceSearchLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.Format, only: [address: 1]

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.Cases

  def mount(params, session, socket) do
    socket = socket |> authenticate_user(session)

    case_investigation = Cases.get_case_investigation(params["id"], socket.assigns.current_user)

    socket
    |> assign_defaults()
    |> assign_page_title("Add place visited")
    |> assign(:result_place_addresses, [])
    |> assign(:query, "")
    |> assign(:case_investigation, case_investigation)
    |> ok()
  end

  def handle_event("suggest-place", %{"query" => query_text}, socket) do
    all_place_addresses = Cases.search_places(query_text)

    socket
    |> assign(:result_place_addresses, all_place_addresses)
    |> noreply()
  end
end
