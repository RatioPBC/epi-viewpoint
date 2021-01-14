defmodule EpicenterWeb.SearchComponent do
  use EpicenterWeb, :live_component

  import EpicenterWeb.IconView, only: [search_icon: 0]

  import EpicenterWeb.LiveHelpers,
    only: [noreply: 1]

  alias Epicenter.Cases

  def handle_event("search", %{"search_form" => %{"term" => term}}, socket) do
    term = term |> String.trim()

    socket =
      case Cases.find_person_id_by_external_id(term) do
        nil -> socket
        person_id -> socket |> push_redirect(to: Routes.profile_path(socket, EpicenterWeb.ProfileLive, person_id))
      end

    socket
    |> noreply()
  end
end
