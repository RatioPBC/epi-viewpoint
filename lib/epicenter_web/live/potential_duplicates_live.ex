defmodule EpicenterWeb.PotentialDuplicatesLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, authenticate_user: 2, ok: 1]
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]

  import EpicenterWeb.Unknown, only: [string_or_unknown: 1]

  alias Epicenter.Cases
  alias EpicenterWeb.Format

  def mount(%{"id" => person_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    person = Cases.get_person(person_id, socket.assigns.current_user) |> Cases.preload_demographics()

    socket
    |> assign_defaults(body_class: "body-background-none")
    |> assign_page_title(Format.person(person))
    |> assign(:person, person)
    |> ok()
  end
end
