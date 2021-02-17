defmodule EpicenterWeb.PeopleFilter do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  alias Epicenter.AuditLog

  def render(assigns) do
    ~H"""
    #status-filter
      = live_patch "All", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :all), class: "button", data: [active: assigns.filter in [:all, nil], role: "people-filter", tid: "all"]
      = live_patch "Pending interview", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :pending_interview), class: "button", data: [active: assigns.filter == :pending_interview, role: "people-filter", tid: "pending_interview"]
      = live_patch "Ongoing interview", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :ongoing_interview), class: "button", data: [active: assigns.filter == :ongoing_interview, role: "people-filter", tid: "ongoing_interview"]
      = live_patch "Isolation monitoring", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :isolation_monitoring), class: "button", data: [active: assigns.filter == :isolation_monitoring, role: "people-filter", tid: "isolation_monitoring"]
    label#assigned-to-me-button
      input type="checkbox" phx-click="toggle-assigned-to-me" checked=@display_people_assigned_to_me data-tid="assigned-to-me-checkbox" phx-target=@myself
      span My assignments only
    """
  end

  def handle_event("toggle-assigned-to-me", _, socket) do
    socket.assigns.on_toggle_assigned_to_me.()
    socket |> noreply()
  end
end

defmodule EpicenterWeb.PeopleLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  import EpicenterWeb.Presenters.PeoplePresenter,
    only: [
      archive_confirmation_message: 1,
      assigned_to_name: 1,
      disabled?: 1,
      external_id: 1,
      full_name: 1,
      selected?: 2
    ]

  import EpicenterWeb.Presenters.CaseInvestigationPresenter, only: [displayable_status: 2]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.CaseInvestigationFilterError
  alias Epicenter.Cases
  alias EpicenterWeb.Format
  alias EpicenterWeb.PeopleFilter

  @clock Application.get_env(:epicenter, :clock)

  def mount(_params, session, socket) do
    socket
    |> assign_defaults()
    |> authenticate_user(session)
    |> assign_page_title("People")
    |> assign_current_date()
    |> assign_reload_message(nil)
    |> assign(:display_people_assigned_to_me, false)
    |> assign_display_import_button()
    |> assign_filter(:all)
    |> load_and_assign_case_investigations()
    |> load_and_assign_users()
    |> assign_selected_to_empty()
    |> ok()
  end

  def handle_event("checkbox-click", %{"value" => "on", "person-id" => person_id} = _value, socket),
    do: socket |> select_person(person_id) |> noreply()

  def handle_event("checkbox-click", %{"person-id" => person_id} = _value, socket),
    do: socket |> deselect_person(person_id) |> noreply()

  def handle_event("form-change", %{"user" => "-unassigned-"}, socket),
    do: handle_event("form-change", %{"user" => nil}, socket)

  def handle_event("form-change", %{"user" => user_id}, socket) do
    {:ok, _} =
      Cases.assign_user_to_people(
        user_id: user_id,
        people_ids:
          socket.assigns.case_investigations
          |> Enum.filter(fn case_investigation ->
            Map.get(socket.assigns.selected_people, case_investigation.person.id)
          end)
          |> Enum.map(fn case_investigation -> case_investigation.person.id end),
        audit_meta: %AuditLog.Meta{
          author_id: socket.assigns.current_user.id,
          reason_action: AuditLog.Revision.update_assignment_bulk_action(),
          reason_event: AuditLog.Revision.people_selected_assignee_event()
        },
        current_user: socket.assigns.current_user
      )

    socket |> assign_selected_to_empty() |> preload_and_assign_case_investigations() |> noreply()
  end

  def handle_event("form-change", _, socket),
    do: socket |> noreply()

  def handle_event("archive", _, socket) do
    for {person_id, _is_selected} <- socket.assigns.selected_people do
      {:ok, _} =
        Cases.archive_person(
          person_id,
          socket.assigns.current_user,
          %AuditLog.Meta{
            author_id: socket.assigns.current_user.id,
            reason_action: AuditLog.Revision.archive_person_action(),
            reason_event: AuditLog.Revision.people_archive_people_event()
          }
        )
    end

    socket |> assign_selected_to_empty() |> load_and_assign_case_investigations() |> noreply()
  end

  def handle_info(:display_people_assigned_to_me_toggled, socket) do
    socket
    |> assign(:display_people_assigned_to_me, !socket.assigns.display_people_assigned_to_me)
    |> load_and_assign_case_investigations()
    |> noreply()
  end

  @case_investigation_filters ~w{all ongoing_interview pending_interview isolation_monitoring}

  def handle_params(%{"filter" => filter}, _url, socket) when filter in @case_investigation_filters,
    do: socket |> assign_filter(filter) |> load_and_assign_case_investigations() |> noreply()

  def handle_params(%{"filter" => unmatched_filter}, _url, _socket),
    do: raise(CaseInvestigationFilterError, user_readable: "Unmatched filter “#{unmatched_filter}”")

  def handle_params(_, _url, socket),
    do: socket |> noreply()

  def on_toggle_assigned_to_me() do
    send(self(), :display_people_assigned_to_me_toggled)
  end

  # # # View helpers

  def page_title(:isolation_monitoring), do: "Isolation monitoring"
  def page_title(:ongoing_interview), do: "Ongoing interviews"
  def page_title(:pending_interview), do: "Pending interviews"
  def page_title(:all), do: "Index case investigations"

  # # # Private

  def assign_current_date(socket) do
    timezone = EpicenterWeb.PresentationConstants.presented_time_zone()
    current_date = @clock.utc_now() |> DateTime.shift_zone!(timezone) |> DateTime.to_date()
    socket |> assign(current_date: current_date)
  end

  defp assign_case_investigations(socket, case_investigations) do
    assign(socket, case_investigations: case_investigations, case_count: length(case_investigations))
  end

  defp deselect_person(%{assigns: %{selected_people: selected_people}} = socket, person_id),
    do: assign(socket, selected_people: Map.delete(selected_people, person_id))

  defp load_and_assign_case_investigations(socket) do
    case_investigations =
      cond do
        socket.assigns.display_people_assigned_to_me ->
          Cases.list_case_investigations(socket.assigns.filter,
            assigned_to_id: socket.assigns.current_user.id,
            user: socket.assigns.current_user
          )

        true ->
          Cases.list_case_investigations(socket.assigns.filter, user: socket.assigns.current_user)
      end

    socket
    |> assign_case_investigations(case_investigations)
    |> preload_and_assign_case_investigations()
  end

  defp preload_and_assign_case_investigations(socket) do
    case_investigations =
      socket.assigns.case_investigations
      |> Cases.preload_initiating_lab_result()
      |> Cases.preload_people()

    assign_case_investigations(socket, case_investigations)
  end

  defp load_and_assign_users(socket),
    do: socket |> assign(users: Accounts.list_users())

  defp select_person(%{assigns: %{selected_people: selected_people}} = socket, person_id),
    do: assign(socket, selected_people: Map.put(selected_people, person_id, true))

  defp assign_filter(socket, filter) when is_binary(filter),
    do: socket |> assign_filter(Euclid.Extra.Atom.from_string(filter))

  defp assign_filter(socket, filter) when is_atom(filter),
    do: socket |> assign(filter: filter, page_title: page_title(filter))

  defp assign_reload_message(socket, message),
    do: socket |> assign(reload_message: message)

  defp assign_selected_to_empty(socket),
    do: socket |> assign(selected_people: %{})

  defp assign_display_import_button(socket),
    do: socket |> assign(display_import_button: socket.assigns.current_user.admin)
end
