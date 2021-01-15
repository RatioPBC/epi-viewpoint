defmodule EpicenterWeb.ContactsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  import EpicenterWeb.Presenters.PeoplePresenter,
    only: [
      assigned_to_name: 1,
      disabled?: 1,
      exposure_date: 1,
      full_name: 1,
      latest_contact_investigation_status: 2,
      selected?: 2
    ]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.Cases

  @clock Application.get_env(:epicenter, :clock)

  def mount(_params, session, socket) do
    socket
    |> assign_defaults()
    |> authenticate_user(session)
    |> assign_page_title("Contacts")
    |> load_and_assign_exposed_people()
    |> load_and_assign_users()
    |> assign_selected_to_empty()
    |> assign_current_date()
    |> ok()
  end

  def handle_event("checkbox-click", %{"value" => "on", "person-id" => person_id} = _value, socket),
    do: socket |> select_person(person_id) |> noreply()

  def handle_info({:people, _people}, socket) do
    socket |> assign_people(Cases.list_exposed_people(socket.assigns.current_user)) |> noreply()
  end

  def handle_info({:assignee_selected, user_id}, socket) do
    {:ok, _updated_people} =
      Cases.assign_user_to_people(
        user_id: user_id,
        people_ids:
          socket.assigns.exposed_people
          |> Enum.filter(fn person -> Map.get(socket.assigns.selected_people, person.id) end)
          |> Euclid.Extra.Enum.pluck(:id),
        audit_meta: %AuditLog.Meta{
          author_id: socket.assigns.current_user.id,
          reason_action: AuditLog.Revision.update_assignment_bulk_action(),
          reason_event: AuditLog.Revision.people_selected_assignee_event()
        },
        current_user: socket.assigns.current_user
      )

    socket |> assign_selected_to_empty() |> assign_people(Cases.list_exposed_people(socket.assigns.current_user)) |> noreply()
  end

  # # # Helpers

  defp assign_people(socket, exposed_people) do
    exposed_people =
      exposed_people
      |> Cases.preload_contact_investigations(socket.assigns.current_user)
      |> Cases.preload_demographics()
      |> Cases.preload_assigned_to()

    AuditLog.view(exposed_people, socket.assigns.current_user)
    assign(socket, exposed_people: exposed_people)
  end

  # # # Private

  defp assign_current_date(socket) do
    timezone = EpicenterWeb.PresentationConstants.presented_time_zone()
    current_date = @clock.utc_now() |> DateTime.shift_zone!(timezone) |> DateTime.to_date()
    socket |> assign(current_date: current_date)
  end

  defp assign_selected_to_empty(socket),
    do: socket |> assign(selected_people: %{})

  defp load_and_assign_exposed_people(socket),
    do: assign_people(socket, Cases.list_exposed_people(socket.assigns.current_user))

  defp load_and_assign_users(socket),
    do: socket |> assign(users: Accounts.list_users())

  defp select_person(%{assigns: %{selected_people: selected_people}} = socket, person_id),
    do: assign(socket, selected_people: Map.put(selected_people, person_id, true))
end
