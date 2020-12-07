defmodule EpicenterWeb.CaseInvestigationNoteSection do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  alias EpicenterWeb.CaseInvestigationNote
  alias EpicenterWeb.CaseInvestigationNoteForm

  def render(assigns) do
    ~H"""
    .case-investigation-notes
      h3.additional_notes Additional Notes
      = component(@socket, CaseInvestigationNoteForm, @case_investigation.id <> "note form", case_investigation_id: @case_investigation.id, current_user_id: @current_user_id, on_add: @on_note_added )
      = for note <- @case_investigation.notes |> Enum.reverse() do
        = component(@socket, CaseInvestigationNote, note.id <> "note", note: note, current_user_id: @current_user_id, on_delete: @on_note_deleted)
    """
  end
end

defmodule EpicenterWeb.CaseInvestigationNote do
  use EpicenterWeb, :live_component

  import EpicenterWeb.LiveHelpers, only: [noreply: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Format

  def preload(assigns) do
    notes =
      assigns
      |> Enum.map(fn a -> a.note end)
      |> Cases.preload_author()

    assigns
    |> Enum.with_index()
    |> Enum.map(fn {a, i} -> Map.put(a, :note, Enum.at(notes, i)) end)
  end

  def render(assigns) do
    ~H"""
    .case-investigation-note data-role="case-investigation-note" data-note-id=@note.id
      .case-investigation-note-header
        span.case-investigation-note-author data-role="case-investigation-note-author" = @note.author.name
        span data-role="case-investigation-note-date" = Format.date(@note.inserted_at)
      .case-investigation-note-text data-role="case-investigation-note-text" = @note.text
      = if @note.author_id == @current_user_id do
        div
          a.case-investigation-delete-link href="#" data-confirm="Remove your note?" phx-click="remove-note" data-role="remove-note" phx-target=@myself Delete
    """
  end

  def handle_event("remove-note", _params, socket) do
    {:ok, _} =
      Cases.delete_investigation_note(socket.assigns.note, %AuditLog.Meta{
        author_id: socket.assigns.current_user_id,
        reason_action: AuditLog.Revision.remove_case_investigation_note_action(),
        reason_event: AuditLog.Revision.remove_case_investigation_note_event()
      })

    socket.assigns.on_delete.(socket.assigns.note)
    socket |> noreply()
  end
end

defmodule EpicenterWeb.ContactInvestigation do
  use EpicenterWeb, :live_component

  import EpicenterWeb.Presenters.ContactInvestigationPresenter, only: [exposing_case_link: 1]

  alias EpicenterWeb.Format

  def render(assigns) do
    ~H"""
    section.contact-investigation data-role="contact-investigation" data-exposure-id="#{@exposure.id}" data-tid="#{@exposure.tid}"
      header
        h2 data-role="contact-investigation-title" Contact investigation #{Format.date(@exposure.most_recent_date_together)}
        span.contact-investigation-timestamp data-role="contact-investigation-timestamp" Created on #{Format.date(@exposure.inserted_at)}
      div data-role="initiating-case"
        span Initiated by index case
        = exposing_case_link(@exposure)
      = if @exposure.under_18 do
        ul.dotted-details data-role="minor-details"
          li data-role="detail" Minor
          li data-role="detail" Guardian: #{@exposure.guardian_name}
          li data-role="detail" Guardian phone: #{Format.phone(@exposure.guardian_phone)}
      ul.dotted-details data-role="exposure-details"
        = if @exposure.household_member do
          li data-role="detail" Same household
        li data-role="detail" #{@exposure.relationship_to_case}
        li data-role="detail" Last together on #{Format.date(@exposure.most_recent_date_together)}
    """
  end
end

defmodule EpicenterWeb.ProfileLive do
  use EpicenterWeb, :live_view

  import Epicenter.Cases.Person, only: [coalesce_demographics: 1]
  import EpicenterWeb.IconView, only: [arrow_down_icon: 0, arrow_right_icon: 2]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2, demographic_field: 3]

  import EpicenterWeb.Presenters.CaseInvestigationPresenter,
    only: [
      contact_details_as_list: 1,
      displayable_clinical_status: 1,
      displayable_interview_status: 1,
      displayable_isolation_monitoring_status: 2,
      displayable_symptoms: 1,
      history_items: 1,
      interview_buttons: 1,
      isolation_monitoring_button: 1,
      isolation_monitoring_history_items: 1
    ]

  import EpicenterWeb.Presenters.LabResultPresenter, only: [pretty_result: 1]
  import EpicenterWeb.Unknown, only: [string_or_unknown: 1, string_or_unknown: 2, list_or_unknown: 1, unknown_value: 0]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Format
  alias EpicenterWeb.CaseInvestigationNoteSection
  alias EpicenterWeb.ContactInvestigation

  @clock Application.get_env(:epicenter, :clock)

  def mount(%{"id" => person_id}, session, socket) do
    person = Cases.get_person(person_id) |> Cases.preload_demographics()

    socket
    |> authenticate_user(session)
    |> assign_page_title(Format.person(person))
    |> assign_person(person)
    |> assign_case_investigations(person)
    |> assign_exposures(person)
    |> assign_users()
    |> assign_current_date()
    |> ok()
  end

  def handle_info({:people, updated_people}, socket) do
    updated_people
    |> Enum.find(&(&1.id == socket.assigns.person.id))
    |> case do
      nil -> socket
      updated_person -> assign_person(socket, updated_person)
    end
    |> noreply()
  end

  def handle_info(:reload_case_investigations, socket) do
    socket |> assign_case_investigations(socket.assigns.person) |> noreply()
  end

  def assign_current_date(socket) do
    timezone = EpicenterWeb.PresentationConstants.presented_time_zone()
    current_date = @clock.utc_now() |> DateTime.shift_zone!(timezone) |> DateTime.to_date()
    socket |> assign(current_date: current_date)
  end

  def handle_event("remove-contact", %{"exposure-id" => exposure_id}, socket) do
    with exposure when not is_nil(exposure) <- Cases.get_exposure(exposure_id) do
      Cases.update_exposure(
        exposure,
        {
          %{deleted_at: NaiveDateTime.utc_now()},
          %AuditLog.Meta{
            author_id: socket.assigns.current_user.id,
            reason_action: AuditLog.Revision.remove_exposure_action(),
            reason_event: AuditLog.Revision.remove_contact_event()
          }
        }
      )
    end

    socket
    |> assign_case_investigations(socket.assigns.person)
    |> noreply()
  end

  def handle_event("form-change", %{"user" => "-unassigned-"}, socket),
    do: handle_event("form-change", %{"user" => nil}, socket)

  def handle_event("form-change", %{"user" => user_id}, socket) do
    {:ok, [updated_person]} =
      Cases.assign_user_to_people(
        user_id: user_id,
        people_ids: [socket.assigns.person.id],
        audit_meta: %AuditLog.Meta{
          author_id: socket.assigns.current_user.id,
          reason_action: AuditLog.Revision.update_assignment_action(),
          reason_event: AuditLog.Revision.profile_selected_assignee_event()
        }
      )

    {:noreply, assign_person(socket, updated_person)}
  end

  def assign_person(socket, person) do
    updated_person =
      person
      |> Cases.preload_lab_results()
      |> Cases.preload_addresses()
      |> Cases.preload_assigned_to()
      |> Cases.preload_demographics()
      |> Cases.preload_emails()
      |> Cases.preload_phones()

    assign(socket, person: updated_person)
  end

  defp assign_case_investigations(socket, person) do
    person = Cases.preload_case_investigations(person)

    case_investigations =
      person.case_investigations
      |> Cases.preload_initiating_lab_result()
      |> Cases.preload_exposures()
      |> Cases.preload_investigation_notes()

    assign(socket, case_investigations: case_investigations)
  end

  defp assign_exposures(socket, person) do
    person = Cases.preload_exposures(person)

    exposures =
      person.exposures
      |> Cases.preload_exposing_case()

    assign(socket, exposures: exposures)
  end

  defp assign_users(socket),
    do: socket |> assign(users: Accounts.list_users())

  # # #

  def age(dob) do
    Date.utc_today() |> Date.diff(dob) |> Integer.floor_div(365)
  end

  def unassigned?(person) do
    person.assigned_to == nil
  end

  def email_addresses(person) do
    person
    |> Map.get(:emails)
    |> Enum.map(& &1.address)
  end

  def selected?(user, person) do
    user == person.assigned_to
  end

  def phone_numbers(person) do
    person
    |> Map.get(:phones)
    |> Enum.map(&Format.phone/1)
  end

  @ethnicity_values_map %{
    "unknown" => "Unknown",
    "declined_to_answer" => "Declined to answer",
    "not_hispanic_latinx_or_spanish_origin" => "Not Hispanic, Latino/a, or Spanish origin",
    "hispanic_latinx_or_spanish_origin" => "Hispanic, Latino/a, or Spanish origin"
  }
  def ethnicity_value(%Epicenter.Cases.Person{} = person), do: person |> coalesce_demographics() |> ethnicity_value()

  def ethnicity_value(%{ethnicity: nil}),
    do: @ethnicity_values_map |> Map.get("unknown")

  def ethnicity_value(%{ethnicity: %{major: nil}}),
    do: @ethnicity_values_map |> Map.get("unknown")

  def ethnicity_value(%{ethnicity: ethnicity}),
    do: @ethnicity_values_map |> Map.get(ethnicity.major)

  @detailed_ethnicity_values_map %{
    "mexican_mexican_american_chicanx" => "Mexican, Mexican American, Chicano/a",
    "puerto_rican" => "Puerto Rican",
    "cuban" => "Cuban",
    "another_hispanic_latinx_or_spanish_origin" => "Another Hispanic, Latino/a or Spanish origin"
  }
  def detailed_ethnicity_value(%Epicenter.Cases.Person{} = person), do: person |> coalesce_demographics() |> detailed_ethnicity_value()

  def detailed_ethnicity_value(detailed_ethnicity) do
    @detailed_ethnicity_values_map |> Map.get(detailed_ethnicity)
  end

  def detailed_ethnicities(%Epicenter.Cases.Person{} = person), do: person |> coalesce_demographics() |> detailed_ethnicities()
  def detailed_ethnicities(%{ethnicity: nil}), do: []
  def detailed_ethnicities(%{ethnicity: %{detailed: nil}}), do: []
  def detailed_ethnicities(person), do: person.ethnicity.detailed
end
