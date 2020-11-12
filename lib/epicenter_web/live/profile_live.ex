defmodule EpicenterWeb.ProfileLive do
  use EpicenterWeb, :live_view

  import Epicenter.Cases.Person, only: [coalesce_demographics: 1]
  import EpicenterWeb.IconView, only: [arrow_down_icon: 0, arrow_right_icon: 2]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2, demographic_field: 3]

  import EpicenterWeb.Profile.CaseInvestigationPresenter,
    only: [
      contact_details_as_list: 1,
      displayable_clinical_status: 1,
      displayable_interview_status: 1,
      displayable_isolation_monitoring_status: 2,
      displayable_symptom_onset_date: 1,
      displayable_symptoms: 1,
      history_items: 1,
      interview_buttons: 1,
      isolation_monitoring_button: 1,
      isolation_monitoring_history_items: 1
    ]

  import EpicenterWeb.Forms.CaseInvestigationNoteForm, only: [add_note_form_builder: 2]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Format
  alias EpicenterWeb.Forms.CaseInvestigationNoteForm.FormFieldData

  @clock Application.get_env(:epicenter, :clock)

  def mount(%{"id" => person_id}, session, socket) do
    if connected?(socket),
      do: Cases.subscribe_to_people()

    person = Cases.get_person(person_id) |> Cases.preload_demographics()

    socket
    |> authenticate_user(session)
    |> assign_page_title(Format.person(person))
    |> assign_person(person)
    |> assign_case_investigations(person)
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

    Cases.broadcast_people([updated_person])

    {:noreply, assign_person(socket, updated_person)}
  end

  def handle_event("save_note", %{"form_field_data" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- FormFieldData.attrs_to_form_changeset(params, socket.assigns.current_user),
         {:form, {:ok, case_investigation_note_attrs}} <- {:form, FormFieldData.case_investigation_note_attrs(form_changeset)},
         {:note, {:ok, _note}} <-
           {:note,
            Cases.create_case_investigation_note(
              {case_investigation_note_attrs,
               %AuditLog.Meta{
                 author_id: socket.assigns.current_user.id,
                 reason_action: "TODO",
                 reason_event: "TODO"
               }}
            )} do
      assign_case_investigations(socket, socket.assigns.person) |> noreply()
    else
      # TODO: error handling
      _ ->
        socket |> noreply()
    end
  end

  def assign_person(socket, person) do
    updated_person = person |> Cases.preload_lab_results() |> Cases.preload_addresses() |> Cases.preload_assigned_to() |> Cases.preload_demographics()
    assign(socket, person: updated_person)
  end

  defp assign_case_investigations(socket, person) do
    person = Cases.preload_case_investigations(person)

    case_investigations =
      person.case_investigations
      |> Cases.preload_initiating_lab_result()
      |> Cases.preload_exposures()
      |> Cases.preload_case_investigation_notes()

    assign(socket, case_investigations: case_investigations)
  end

  defp assign_users(socket),
    do: socket |> assign(users: Accounts.list_users())

  # # #

  @unknown_text "Unknown"

  def age(dob) do
    Date.utc_today() |> Date.diff(dob) |> Integer.floor_div(365)
  end

  def unassigned?(person) do
    person.assigned_to == nil
  end

  def email_addresses(person) do
    person
    |> Cases.preload_emails()
    |> Map.get(:emails)
    |> Enum.map(& &1.address)
  end

  def selected?(user, person) do
    user == person.assigned_to
  end

  def phone_numbers(person) do
    person
    |> Cases.preload_phones()
    |> Map.get(:phones)
    |> Enum.map(&Format.phone/1)
  end

  def string_or_unknown(value, text \\ @unknown_text) do
    if Euclid.Exists.present?(value),
      do: value,
      else: unknown_value(text)
  end

  def list_or_unknown(values) do
    if Euclid.Exists.present?(values) do
      Phoenix.HTML.Tag.content_tag :ul do
        Enum.map(values, &Phoenix.HTML.Tag.content_tag(:li, &1))
      end
    else
      unknown_value()
    end
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

  def unknown_value(text \\ @unknown_text) do
    Phoenix.HTML.Tag.content_tag(:span, text, class: "unknown")
  end
end
