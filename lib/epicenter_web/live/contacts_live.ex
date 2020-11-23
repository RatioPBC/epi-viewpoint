defmodule EpicenterWeb.ContactsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, ok: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias EpicenterWeb.Format

  def mount(_params, session, socket) do
    socket
    |> authenticate_user(session)
    |> assign_page_title("Contacts")
    |> load_and_assign_exposed_people()
    |> ok()
  end

  def exposure_date(person) do
    person.exposures |> hd() |> Map.get(:most_recent_date_together) |> Format.date()
  end

  def full_name(person) do
    demographic = Person.coalesce_demographics(person)
    [demographic.first_name, demographic.last_name] |> Euclid.Exists.filter() |> Enum.join(" ")
  end

  def assigned_to_name(%Person{assigned_to: nil}),
    do: ""

  def assigned_to_name(%Person{assigned_to: assignee}),
    do: assignee.name

  # # #

  defp load_and_assign_exposed_people(socket) do
    exposed_people =
      Cases.list_exposed_people()
      |> Cases.preload_exposures_for_people()
      |> Cases.preload_demographics()
      |> Cases.preload_assigned_to()

    assign(socket, exposed_people: exposed_people)
  end
end
