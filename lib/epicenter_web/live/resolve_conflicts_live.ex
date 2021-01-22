defmodule EpicenterWeb.ResolveConflictsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, authenticate_user: 2, ok: 1]

  alias Epicenter.Cases

  def mount(%{"person_ids" => comma_separated_person_ids} = _params, session, socket) do
    socket = socket |> authenticate_user(session)

    socket
    |> assign_defaults(body_class: "body-background-none")
    |> assign_page_title("Resolve Conflicts")
    |> assign_person_ids(comma_separated_person_ids)
    |> ok()
  end

  # # #

  defp assign_person_ids(socket, comma_separated_person_ids) do
    person_ids = String.split(comma_separated_person_ids, ",")
    people = Cases.get_people(person_ids, socket.assigns.current_user)

    socket
    |> assign(:people, people)
  end
end
