defmodule EpicenterWeb.PotentialDuplicatesLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [arrow_right_icon: 0, back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]
  import EpicenterWeb.Unknown, only: [list_or_unknown: 2]
  import Euclid.Extra.Enum, only: [pluck: 2]

  alias Epicenter.Cases
  alias Epicenter.Extra
  alias EpicenterWeb.Format

  def mount(%{"id" => person_id}, session, socket) do
    socket = socket |> authenticate_user(session)

    person =
      Cases.get_person(person_id, socket.assigns.current_user)
      |> Cases.preload_demographics()
      |> Cases.preload_phones()
      |> Cases.preload_addresses()

    duplicate_people =
      Cases.list_duplicate_people(person, socket.assigns.current_user)
      |> Cases.preload_demographics()
      |> Cases.preload_phones()
      |> Cases.preload_addresses()
      |> Enum.sort_by(&Format.person(&1), &Extra.String.case_insensitive_sort_fun/2)

    socket
    |> assign_defaults(body_class: "body-background-none")
    |> assign_page_title(Format.person(person))
    |> assign(:person, person)
    |> assign(:duplicate_people, [person | duplicate_people])
    |> assign(:selected_people, [])
    |> ok()
  end

  def handle_event("set-selected-people", params, socket) do
    selected_people = params |> Map.get("selected_people") || []
    socket |> assign(:selected_people, selected_people) |> noreply
  end

  def handle_event("merge-selected-people", _params, socket) do
    duplicate_person_ids = socket.assigns[:selected_people] |> Enum.join(",")

    socket
    |> push_navigate(
      to:
        "#{Routes.resolve_conflicts_path(socket, EpicenterWeb.ResolveConflictsLive, socket.assigns[:person])}?duplicate_person_ids=#{
          duplicate_person_ids
        }"
    )
    |> noreply
  end

  defp selected?(selected_people, person) do
    person.id in selected_people
  end
end
