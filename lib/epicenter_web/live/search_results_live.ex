defmodule EpicenterWeb.SearchResultsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, ok: 1]

  def mount(_params, session, socket) do
    socket
    |> assign_defaults()
    |> authenticate_user(session)
    |> assign_page_title("Search Results")
    |> assign(:search_term, "")
    |> ok()
  end
end
