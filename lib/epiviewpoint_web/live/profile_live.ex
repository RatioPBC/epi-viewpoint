defmodule EpiViewpointWeb.ProfileLive do
  use EpiViewpointWeb, :live_view

  import EpiViewpoint.Cases.Person, only: [coalesce_demographics: 1]
  import EpiViewpointWeb.IconView, only: [arrow_down_icon: 0]
  import EpiViewpointWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]
  import EpiViewpointWeb.PersonHelpers, only: [demographic_field: 2, demographic_field: 3]

  import EpiViewpointWeb.Presenters.CaseInvestigationPresenter,
    only: [
      contact_details_as_list: 1,
      displayable_interview_status: 1,
      displayable_isolation_monitoring_status: 2,
      history_items: 1,
      interview_buttons: 1,
      isolation_monitoring_button: 1,
      isolation_monitoring_history_items: 1
    ]

  import EpiViewpointWeb.Presenters.InvestigationPresenter, only: [displayable_clinical_status: 1, displayable_symptoms: 1]
  import EpiViewpointWeb.Presenters.LabResultPresenter, only: [pretty_result: 1]
  import EpiViewpointWeb.Presenters.PeoplePresenter, only: [is_archived?: 1, is_editable?: 1]
  import EpiViewpointWeb.Presenters.PlacePresenter, only: [address: 1]
  import EpiViewpointWeb.Unknown, only: [string_or_unknown: 1, string_or_unknown: 2, list_or_unknown: 1, unknown_value: 0]

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.AuditLog
  alias EpiViewpoint.AuditingRepo
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.CaseInvestigation
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpointWeb.ContactInvestigation
  alias EpiViewpointWeb.Format
  alias EpiViewpointWeb.InvestigationNotesSection

  @clock Application.compile_env(:epiviewpoint, :clock)

  def mount(%{"id" => person_id}, session, socket) do
    socket = socket |> authenticate_user(session)

    potential_person = Cases.get_person(person_id, socket.assigns.current_user)
    person = canonical_person(potential_person, socket.assigns.current_user, %{}) |> Cases.preload_demographics()

    socket
    |> assign_defaults(body_class: "body-background-color")
    |> assign_page_title(Format.person(person))
    |> assign_updated_person(person)
    |> assign_case_investigations(person)
    |> assign_potential_duplicate_count()
    |> assign_users()
    |> assign_current_date()
    |> ok()
  end

  def handle_info({:people, updated_people}, socket) do
    updated_people
    |> Enum.find(&(&1.id == socket.assigns.person.id))
    |> case do
      nil -> socket
      updated_person -> assign_updated_person(socket, updated_person)
    end
    |> noreply()
  end

  def handle_info({:add_note, note_attrs, {foreign_key_name, subject}}, socket) do
    note_attrs = Map.merge(note_attrs, %{foreign_key_name => subject.id, author_id: socket.assigns.current_user.id})
    {reason_action, reason_event} = audit_log_data_for_adding_note(subject)

    Cases.create_investigation_note(
      {note_attrs,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: reason_action,
         reason_event: reason_event
       }}
    )

    handle_info(:reload_investigations, socket)
  end

  def handle_info({:delete_note, note, subject}, socket) do
    {reason_action, reason_event} = audit_log_data_for_deleting_note(subject)

    {:ok, _} =
      Cases.delete_investigation_note(note, %AuditLog.Meta{
        author_id: socket.assigns.current_user.id,
        reason_action: reason_action,
        reason_event: reason_event
      })

    handle_info(:reload_investigations, socket)
  end

  def handle_info(:reload_investigations, socket) do
    socket
    |> assign_case_investigations(socket.assigns.person)
    |> assign_contact_investigations(socket.assigns.person)
    |> noreply()
  end

  defp audit_log_data_for_adding_note(%CaseInvestigation{}) do
    {
      AuditLog.Revision.create_case_investigation_note_action(),
      AuditLog.Revision.profile_case_investigation_note_submission_event()
    }
  end

  defp audit_log_data_for_adding_note(%ContactInvestigations.ContactInvestigation{}) do
    {
      AuditLog.Revision.create_contact_investigation_note_action(),
      AuditLog.Revision.profile_contact_investigation_note_submission_event()
    }
  end

  def assign_current_date(socket) do
    timezone = EpiViewpointWeb.PresentationConstants.presented_time_zone()
    current_date = @clock.utc_now() |> DateTime.shift_zone!(timezone) |> DateTime.to_date()
    socket |> assign(current_date: current_date)
  end

  def on_note_added(note_attrs, %CaseInvestigation{} = subject) do
    send(self(), {:add_note, note_attrs, {:case_investigation_id, subject}})
  end

  def on_note_added(note_attrs, %ContactInvestigations.ContactInvestigation{} = subject) do
    send(self(), {:add_note, note_attrs, {:contact_investigation_id, subject}})
  end

  defp audit_log_data_for_deleting_note(%CaseInvestigation{}) do
    {
      AuditLog.Revision.delete_case_investigation_note_action(),
      AuditLog.Revision.profile_case_investigation_note_deletion_event()
    }
  end

  defp audit_log_data_for_deleting_note(%ContactInvestigations.ContactInvestigation{}) do
    {
      AuditLog.Revision.delete_contact_investigation_note_action(),
      AuditLog.Revision.profile_contact_investigation_note_deletion_event()
    }
  end

  def on_note_deleted(note, subject) do
    send(self(), {:delete_note, note, subject})
  end

  def handle_event("archive", _params, socket) do
    {:ok, updated_person} =
      Cases.archive_person(socket.assigns.person.id, socket.assigns.current_user, %AuditLog.Meta{
        author_id: socket.assigns.current_user.id,
        reason_action: AuditLog.Revision.archive_person_action(),
        reason_event: AuditLog.Revision.profile_archive_person_event()
      })

    {:noreply, assign_updated_person(socket, updated_person)}
  end

  def handle_event("remove-contact", %{"contact-investigation-id" => contact_investigation_id}, socket) do
    with contact_investigation when not is_nil(contact_investigation) <-
           ContactInvestigations.get(contact_investigation_id, socket.assigns.current_user) do
      ContactInvestigations.update(
        contact_investigation,
        {
          %{deleted_at: NaiveDateTime.utc_now()},
          %AuditLog.Meta{
            author_id: socket.assigns.current_user.id,
            reason_action: AuditLog.Revision.remove_contact_investigation_action(),
            reason_event: AuditLog.Revision.remove_contact_event()
          }
        }
      )
    end

    socket
    |> assign_case_investigations(socket.assigns.person)
    |> noreply()
  end

  def handle_event("remove-visit", %{"visit-id" => visit_id}, socket) do
    with visit when not is_nil(visit) <-
           Cases.get_visit(visit_id) do
      Cases.update_visit(
        visit,
        {
          %{deleted_at: NaiveDateTime.utc_now()},
          %AuditLog.Meta{
            author_id: socket.assigns.current_user.id,
            reason_action: AuditLog.Revision.remove_contact_investigation_action(),
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
        },
        current_user: socket.assigns.current_user
      )

    {:noreply, assign_updated_person(socket, updated_person)}
  end

  def handle_event("unarchive", _params, socket) do
    {:ok, updated_person} =
      Cases.unarchive_person(socket.assigns.person.id, socket.assigns.current_user, %AuditLog.Meta{
        author_id: socket.assigns.current_user.id,
        reason_action: AuditLog.Revision.unarchive_person_action(),
        reason_event: AuditLog.Revision.profile_unarchive_person_event()
      })

    {:noreply, assign_updated_person(socket, updated_person)}
  end

  def assign_updated_person(socket, person) do
    updated_person =
      person
      |> Cases.preload_lab_results()
      |> Cases.preload_addresses()
      |> Cases.preload_assigned_to()
      |> Cases.preload_demographics()
      |> Cases.preload_emails()
      |> Cases.preload_phones()
      |> Cases.preload_archived_by()

    socket
    |> assign(person: updated_person)
    |> assign_contact_investigations(person)
  end

  defp assign_case_investigations(socket, person) do
    person = Cases.preload_case_investigations(person)

    case_investigations =
      person.case_investigations
      |> Cases.preload_initiating_lab_result()
      |> Cases.preload_contact_investigations(socket.assigns.current_user)
      |> Cases.preload_investigation_notes()
      |> Cases.preload_visit_details()

    case_investigations_contacts_persons =
      Enum.flat_map(case_investigations, & &1.contact_investigations)
      |> Enum.map(& &1.exposed_person)

    AuditingRepo.view(case_investigations_contacts_persons, socket.assigns.current_user)

    assign(socket, case_investigations: case_investigations)
  end

  defp assign_contact_investigations(socket, person) do
    person = Cases.preload_contact_investigations(person, socket.assigns.current_user)

    contact_investigations =
      person.contact_investigations
      |> ContactInvestigations.preload_exposing_case()
      |> Cases.preload_investigation_notes()

    assign(socket, contact_investigations: contact_investigations)
  end

  defp assign_potential_duplicate_count(socket) do
    count =
      if is_archived?(socket.assigns.person) do
        0
      else
        Cases.count_duplicate_people(socket.assigns.person)
      end

    assign(socket, potential_duplicate_count: count)
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
  def ethnicity_value(%EpiViewpoint.Cases.Person{} = person), do: person |> coalesce_demographics() |> ethnicity_value()

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
  def detailed_ethnicity_value(%EpiViewpoint.Cases.Person{} = person), do: person |> coalesce_demographics() |> detailed_ethnicity_value()

  def detailed_ethnicity_value(detailed_ethnicity) do
    @detailed_ethnicity_values_map |> Map.get(detailed_ethnicity)
  end

  def detailed_ethnicities(%EpiViewpoint.Cases.Person{} = person), do: person |> coalesce_demographics() |> detailed_ethnicities()
  def detailed_ethnicities(%{ethnicity: nil}), do: []
  def detailed_ethnicities(%{ethnicity: %{detailed: nil}}), do: []
  def detailed_ethnicities(person), do: person.ethnicity.detailed

  defp canonical_person(%Person{merged_into_id: nil} = person, _current_user, _people_seen), do: person

  defp canonical_person(%Person{merged_into_id: merged_into_id} = person, current_user, people_seen) do
    if people_seen[person.id] do
      person
    else
      canonical_person(Cases.get_person(merged_into_id, current_user), current_user, Map.put(people_seen, person.id, true))
    end
  end
end
