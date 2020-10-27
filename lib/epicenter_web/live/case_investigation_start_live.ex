defmodule EpicenterWeb.CaseInvestigationStartLive do
  use EpicenterWeb, :live_view

  #  import EpicenterWeb.IconView, only: [plus_icon: 0, arrow_down_icon: 0, back_icon: 0, trash_icon: 0]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.Cases

  def mount(%{"id" => person_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    person = Cases.get_person(person_id)

    socket
    |> assign_page_title("Start Case Investigation")
    |> assign(person: person)
    |> ok()
  end

  def handle_event("save", %{}, socket) do
    # |> push_redirect(to: Routes.profile_path(socket, EpicenterWeb.ProfileLive, person))}
    noreply(socket)
  end

  # # #
end
