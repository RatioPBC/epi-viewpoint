defmodule EpicenterWeb.PeopleFilter do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  def render(assigns) do
    ~H"""
    #status-filter
      = live_patch "All", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :with_positive_lab_results), class: "button", data: [active: assigns.filter in [:with_positive_lab_results, nil], role: "people-filter", tid: "all"]
      = live_patch "Pending interview", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :with_pending_interview), class: "button", data: [active: assigns.filter == :with_pending_interview, role: "people-filter", tid: "with_pending_interview"]
      = live_patch "Ongoing interview", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :with_ongoing_interview), class: "button", data: [active: assigns.filter == :with_ongoing_interview, role: "people-filter", tid: "with_ongoing_interview"]
      = live_patch "Isolation monitoring", to: Routes.people_path(@socket, EpicenterWeb.PeopleLive, filter: :with_isolation_monitoring), class: "button", data: [active: assigns.filter == :with_isolation_monitoring, role: "people-filter", tid: "with_isolation_monitoring"]
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
      assigned_to_name: 1,
      disabled?: 1,
      external_id: 1,
      full_name: 1,
      latest_case_investigation_status: 2,
      selected?: 2
    ]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.CaseInvestigationFilterError
  alias Epicenter.Cases
  alias EpicenterWeb.PeopleFilter
  alias EpicenterWeb.Presenters.LabResultPresenter

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
    |> assign_filter(:with_positive_lab_results)
    |> load_and_assign_people()
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
    {:ok, updated_people} =
      Cases.assign_user_to_people(
        user_id: user_id,
        people_ids:
          socket.assigns.people
          |> Enum.filter(fn person -> Map.get(socket.assigns.selected_people, person.id) end)
          |> Euclid.Extra.Enum.pluck(:id),
        audit_meta: %AuditLog.Meta{
          author_id: socket.assigns.current_user.id,
          reason_action: AuditLog.Revision.update_assignment_bulk_action(),
          reason_event: AuditLog.Revision.people_selected_assignee_event()
        }
      )

    socket |> assign_selected_to_empty() |> refresh_existing_people(updated_people) |> noreply()
  end

  def handle_event("form-change", _, socket),
    do: socket |> noreply()

  def handle_info(:display_people_assigned_to_me_toggled, socket) do
    socket
    |> assign(:display_people_assigned_to_me, !socket.assigns.display_people_assigned_to_me)
    |> load_and_assign_people()
    |> noreply()
  end

  def handle_info({:people, updated_people}, socket),
    do: socket |> assign_selected_to_empty() |> refresh_existing_people(updated_people) |> prompt_to_reload(updated_people) |> noreply()

  @case_investigation_filters ~w{with_ongoing_interview with_pending_interview with_positive_lab_results with_isolation_monitoring}

  def handle_params(%{"filter" => filter}, _url, socket) when filter in @case_investigation_filters,
    do: socket |> assign_filter(filter) |> load_and_assign_people() |> noreply()

  def handle_params(%{"filter" => unmatched_filter}, _url, _socket),
    do: raise(CaseInvestigationFilterError, user_readable: "Unmatched filter “#{unmatched_filter}”")

  def handle_params(_, _url, socket),
    do: socket |> noreply()

  def on_toggle_assigned_to_me() do
    send(self(), :display_people_assigned_to_me_toggled)
  end

  # # # View helpers

  def page_title(:contacts), do: "Contacts"
  def page_title(:with_isolation_monitoring), do: "Isolation monitoring"
  def page_title(:with_ongoing_interview), do: "Ongoing interviews"
  def page_title(:with_pending_interview), do: "Pending interviews"
  def page_title(:with_positive_lab_results), do: "Index Cases"

  # # # Private

  def assign_current_date(socket) do
    timezone = EpicenterWeb.PresentationConstants.presented_time_zone()
    current_date = @clock.utc_now() |> DateTime.shift_zone!(timezone) |> DateTime.to_date()
    socket |> assign(current_date: current_date)
  end

  defp assign_people(socket, people),
    do: assign(socket, people: people, person_count: length(people))

  defp deselect_person(%{assigns: %{selected_people: selected_people}} = socket, person_id),
    do: assign(socket, selected_people: Map.delete(selected_people, person_id))

  defp load_and_assign_people(socket) do
    people =
      cond do
        socket.assigns.display_people_assigned_to_me ->
          Cases.list_people(socket.assigns.filter, assigned_to_id: socket.assigns.current_user.id)

        true ->
          Cases.list_people(socket.assigns.filter)
      end

    socket
    |> assign_people(people)
    |> preload_and_assign_people()
  end

  defp preload_and_assign_people(socket) do
    people =
      socket.assigns.people
      |> Cases.preload_lab_results()
      |> Cases.preload_assigned_to()
      |> Cases.preload_demographics()
      |> Cases.preload_case_investigations()

    assign_people(socket, people)
  end

  defp load_and_assign_users(socket),
    do: socket |> assign(users: Accounts.list_users())

  defp prompt_to_reload(socket, _people) do
    assign_reload_message(socket, "Changes have been made. Click here to refresh.")
  end

  defp refresh_existing_people(socket, updated_people) do
    id_to_people_map = updated_people |> Enum.reduce(%{}, fn person, acc -> acc |> Map.put(person.id, person) end)
    refreshed_people = socket.assigns.people |> Enum.map(fn person -> Map.get(id_to_people_map, person.id, person) end)

    assign_people(socket, refreshed_people)
    |> preload_and_assign_people()
  end

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
