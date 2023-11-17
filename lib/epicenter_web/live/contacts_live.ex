defmodule EpicenterWeb.ContactsFilter do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  alias Epicenter.AuditLog

  def render(assigns) do
    ~M"""
    #status-filter
      = live_patch "All", to: Routes.contacts_path(@socket, EpicenterWeb.ContactsLive, filter: :with_contact_investigation), class: "button", data: [active: assigns.filter in [:with_contact_investigation, nil], role: "contacts-filter", tid: "all"]
      = live_patch "Pending interview", to: Routes.contacts_path(@socket, EpicenterWeb.ContactsLive, filter: :with_pending_interview), class: "button", data: [active: assigns.filter == :with_pending_interview, role: "contacts-filter", tid: "with_pending_interview"]
      = live_patch "Ongoing interview", to: Routes.contacts_path(@socket, EpicenterWeb.ContactsLive, filter: :with_ongoing_interview), class: "button", data: [active: assigns.filter == :with_ongoing_interview, role: "contacts-filter", tid: "with_ongoing_interview"]
      = live_patch "Quarantine monitoring", to: Routes.contacts_path(@socket, EpicenterWeb.ContactsLive, filter: :with_quarantine_monitoring), class: "button", data: [active: assigns.filter == :with_quarantine_monitoring, role: "contacts-filter", tid: "with_quarantine_monitoring"]
    """
    |> Map.put(:root, true)
  end
end

defmodule EpicenterWeb.ContactsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  import EpicenterWeb.Presenters.PeoplePresenter,
    only: [
      archive_confirmation_message: 1,
      assigned_to_name: 1,
      disabled?: 1,
      exposure_date: 1,
      full_name: 1,
      latest_contact_investigation_status: 2,
      selected?: 2
    ]

  alias Epicenter.Accounts
  alias Epicenter.AuditingRepo
  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.ContactsFilterError
  alias EpicenterWeb.ContactsFilter

  @clock Application.compile_env(:epicenter, :clock)

  def mount(_params, session, socket) do
    socket
    |> assign_defaults()
    |> authenticate_user(session)
    |> assign_page_title("Contacts")
    |> assign_filter(:with_contact_investigation)
    |> load_and_assign_exposed_people()
    |> load_and_assign_users()
    |> assign_selected_to_empty()
    |> assign_current_date()
    |> ok()
  end

  def handle_event("archive", _, socket) do
    for {person_id, _is_selected} <- socket.assigns.selected_people do
      {:ok, _} =
        Cases.archive_person(
          person_id,
          socket.assigns.current_user,
          %AuditLog.Meta{
            author_id: socket.assigns.current_user.id,
            reason_action: AuditLog.Revision.archive_person_action(),
            reason_event: AuditLog.Revision.contacts_archive_people_event()
          }
        )
    end

    socket |> assign_selected_to_empty() |> load_and_assign_exposed_people() |> noreply()
  end

  def handle_event("checkbox-click", %{"value" => "on", "person-id" => person_id} = _value, socket),
    do: socket |> select_person(person_id) |> noreply()

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

    socket
    |> assign_selected_to_empty()
    |> load_and_assign_exposed_people()
    |> noreply()
  end

  @contacts_filters ~w{with_contact_investigation with_ongoing_interview with_pending_interview with_quarantine_monitoring}

  def handle_params(%{"filter" => filter}, _url, socket) when filter in @contacts_filters,
    do: socket |> assign_filter(filter) |> load_and_assign_exposed_people() |> noreply()

  def handle_params(%{"filter" => unmatched_filter}, _url, _socket),
    do: raise(ContactsFilterError, user_readable: "Unmatched filter “#{unmatched_filter}”")

  def handle_params(_, _url, socket),
    do: socket |> noreply()

  # # # Helpers

  defp assign_people(socket, exposed_people) do
    exposed_people =
      exposed_people
      |> Cases.preload_contact_investigations(socket.assigns.current_user)
      |> Cases.preload_demographics()
      |> Cases.preload_assigned_to()

    AuditingRepo.view(exposed_people, socket.assigns.current_user)
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
    do:
      socket
      |> assign_people(ContactInvestigations.list_exposed_people(socket.assigns.filter, socket.assigns.current_user, reject_archived_people: true))

  defp load_and_assign_users(socket),
    do: socket |> assign(users: Accounts.list_users())

  defp select_person(%{assigns: %{selected_people: selected_people}} = socket, person_id),
    do: assign(socket, selected_people: Map.put(selected_people, person_id, true))

  defp assign_filter(socket, filter) when is_binary(filter),
    do: socket |> assign_filter(Euclid.Extra.Atom.from_string(filter))

  defp assign_filter(socket, filter) when is_atom(filter) do
    page_title =
      case filter do
        :with_contact_investigation -> "Contact investigations"
        :with_ongoing_interview -> "Ongoing interviews"
        :with_pending_interview -> "Pending interviews"
        :with_quarantine_monitoring -> "Quarantine monitoring"
      end

    socket |> assign(filter: filter, page_title: page_title)
  end
end
