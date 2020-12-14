defmodule EpicenterWeb.CaseInvestigationContactLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.ContactInvestigation
  alias Epicenter.Cases.Person
  alias EpicenterWeb.Format
  alias EpicenterWeb.Form

  defmodule ContactForm do
    use Ecto.Schema

    import Ecto.Changeset

    # TODO: can we remove these nested aliases?
    alias Epicenter.Cases.ContactInvestigation
    alias Epicenter.Cases.Person
    alias Epicenter.DateParser
    alias Epicenter.Validation

    embedded_schema do
      field :exposure_id, :string
      field :person_id, :string
      field :phone_id, :string
      field :demographic_id, :string
      field :guardian_name, :string
      field :guardian_phone, :string
      field :first_name, :string
      field :last_name, :string
      field :relationship_to_case, :string
      field :same_household, :boolean
      field :under_18, :boolean
      field :phone, :string
      field :preferred_language, :string
      field :most_recent_date_together, :string
    end

    def changeset(%ContactInvestigation{} = contact_investigation, attrs) do
      person = contact_investigation.exposed_person || %Person{demographics: [], phones: []}
      demographic = Person.coalesce_demographics(person)
      phone = List.first(person.phones) || %{id: nil, number: ""}

      %__MODULE__{
        exposure_id: contact_investigation.id,
        guardian_name: contact_investigation.guardian_name,
        guardian_phone: contact_investigation.guardian_phone,
        person_id: person.id,
        demographic_id: demographic.id,
        phone_id: phone.id,
        first_name: demographic.first_name || "",
        last_name: demographic.last_name || "",
        phone: phone.number,
        under_18: contact_investigation.under_18 || false,
        same_household: contact_investigation.household_member || false,
        relationship_to_case: contact_investigation.relationship_to_case,
        preferred_language: demographic.preferred_language,
        most_recent_date_together: Format.date(contact_investigation.most_recent_date_together)
      }
      |> cast(attrs, [
        :first_name,
        :last_name,
        :relationship_to_case,
        :same_household,
        :guardian_name,
        :guardian_phone,
        :under_18,
        :phone,
        :preferred_language,
        :most_recent_date_together
      ])
      |> validate_required([
        :first_name,
        :last_name,
        :relationship_to_case,
        :same_household,
        :under_18,
        :most_recent_date_together
      ])
      |> ContactInvestigation.validate_guardian_fields()
      |> Validation.validate_date(:most_recent_date_together)
    end

    def contact_params(%Ecto.Changeset{} = formdata) do
      with {:ok, data} <- apply_action(formdata, :insert) do
        phone =
          if Euclid.Exists.present?(data.phone) do
            %{source: "form", number: data.phone}
          else
            nil
          end

        {:ok,
         %{
           id: data.exposure_id,
           guardian_name: data.guardian_name,
           guardian_phone: data.guardian_phone,
           most_recent_date_together: DateParser.parse_mm_dd_yyyy!(data.most_recent_date_together),
           relationship_to_case: data.relationship_to_case,
           under_18: data.under_18,
           household_member: data.same_household,
           exposed_person: %{
             id: data.person_id,
             form_demographic: %{
               id: data.demographic_id,
               source: "form",
               first_name: data.first_name,
               last_name: data.last_name,
               preferred_language: data.preferred_language
             },
             additive_phone: phone
           }
         }}
      end
    end
  end

  def mount(%{"case_investigation_id" => case_investigation_id} = params, session, socket) do
    case_investigation = case_investigation_id |> Cases.get_case_investigation() |> Cases.preload_person() |> Cases.preload_initiating_lab_result()

    contact_investigation =
      if id = params["id"] do
        Cases.get_contact_investigation(id) |> Cases.preload_exposed_person()
      else
        %ContactInvestigation{exposed_person: %Person{demographics: [], phones: []}}
      end

    socket
    |> authenticate_user(session)
    |> assign_page_title("Case Investigation Contact")
    |> assign_form_changeset(ContactForm.changeset(contact_investigation, %{}))
    |> assign(:contact_investigation, contact_investigation)
    |> assign(:case_investigation, case_investigation)
    |> ok()
  end

  def handle_event("change", %{"contact_form" => params}, socket) do
    socket
    |> assign_form_changeset(ContactForm.changeset(socket.assigns.contact_investigation, params))
    |> noreply()
  end

  def handle_event("save", %{"contact_form" => params}, socket) do
    contact_investigation = socket.assigns.contact_investigation

    with {:form, {:ok, data}} <- {:form, ContactForm.changeset(contact_investigation, params) |> ContactForm.contact_params()},
         data = data |> Map.put(:exposing_case_id, socket.assigns.case_investigation.id),
         {:ok, _} <- create_or_update_contact_investigation(contact_investigation, data, socket.assigns.current_user) do
      socket
      |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.case_investigation.person)}#case-investigations")
      |> noreply()
    else
      {:form, {:error, changeset}} ->
        socket
        |> assign_form_changeset(changeset, "Check errors above")
        |> noreply()
    end
  end

  defp create_or_update_contact_investigation(contact_investigation, data, author) do
    if data.id do
      Cases.update_contact_investigation(
        contact_investigation,
        {data,
         %Epicenter.AuditLog.Meta{
           author_id: author.id,
           reason_action: AuditLog.Revision.create_contact_action(),
           reason_event: AuditLog.Revision.create_contact_event()
         }}
      )
    else
      Cases.create_contact_investigation(
        {data,
         %Epicenter.AuditLog.Meta{
           author_id: author.id,
           reason_action: AuditLog.Revision.update_contact_investigation_action(),
           reason_event: AuditLog.Revision.update_contact_event()
         }}
      )
    end
  end

  @preferred_language_options [
    {"English", "English"},
    {"Spanish", "Spanish"},
    {"Arabic", "Arabic"},
    {"Bengali", "Bengali"},
    {"Chinese (Cantonese)", "Chinese (Cantonese)"},
    {"Chinese (Mandarin)", "Chinese (Mandarin)"},
    {"French", "French"},
    {"Haitian Creole", "Haitian Creole"},
    {"Hebrew", "Hebrew"},
    {"Hindi", "Hindi"},
    {"Italian", "Italian"},
    {"Korean", "Korean"},
    {"Polish", "Polish"},
    {"Russian", "Russian"},
    {"Swahili", "Swahili"},
    {"Yiddish", "Yiddish"}
  ]

  @relationship_options [
    "Family",
    "Partner or roommate",
    "Healthcare worker",
    "Neighbor",
    "Co-worker",
    "Friend",
    "Teacher or childcare",
    "Service provider"
  ]
  def contact_form_builder(form, case_investigation, form_error) do
    onset_date = case_investigation.symptom_onset_on
    sampled_date = case_investigation.initiating_lab_result.sampled_on
    infectious_seed_date = onset_date || sampled_date

    infectious_period =
      if(infectious_seed_date,
        do: "#{infectious_seed_date |> Date.add(-2) |> Format.date()} - #{infectious_seed_date |> Date.add(10) |> Format.date()}",
        else: "Unavailable"
      )

    under_18 = Epicenter.Extra.Changeset.get_field_from_changeset(form.source, :under_18)

    contact_information = fn
      form, true = _under_18 ->
        form
        |> Form.line(&Form.text_field(&1, :guardian_name, "Guardian's name", span: 4))
        |> Form.line(&Form.text_field(&1, :guardian_phone, "Guardian's phone", span: 4))

      form, _ = _under_18 ->
        form
        |> Form.line(&Form.text_field(&1, :phone, "Phone", span: 4))
    end

    Form.new(form)
    |> Form.line(
      &Form.content_div(
        &1,
        "Include people who live in the same house, or are from workspaces, shared meals, volunteer activities, playing sports, parties, places of worship, gym or exercise class, gatherings or social events, sporting events, and concerts.",
        span: 8
      )
    )
    |> Form.line(fn line ->
      line
      |> Form.text_field(:first_name, "First name")
      |> Form.text_field(:last_name, "Last name")
    end)
    |> Form.line(&Form.radio_button_list(&1, :relationship_to_case, "Relationship to case", @relationship_options, span: 4))
    |> Form.line(&Form.checkbox_field(&1, :same_household, nil, "This person lives in the same household", span: 8))
    |> Form.line(&Form.checkbox_field(&1, :under_18, "Age", "This person is under 18 years old", span: 8))
    |> contact_information.(under_18)
    |> Form.line(&Form.radio_button_list(&1, :preferred_language, "Preferred Language", @preferred_language_options, span: 4))
    |> Form.line(
      &Form.date_field(
        &1,
        :most_recent_date_together,
        "Most recent day together",
        explanation_text:
          Enum.join(
            [
              "Onset date: #{if(onset_date, do: Format.date(onset_date), else: "Unavailable")}",
              "Positive lab sample: #{if(sampled_date, do: Format.date(sampled_date), else: "Unavailable")}",
              "Infectious period: #{infectious_period}"
            ],
            "\n"
          ),
        span: 4
      )
    )
    |> Form.line(&Form.footer(&1, form_error, span: 4))
    |> Form.safe()
  end

  def confirmation_prompt(changeset), do: if(changeset.changes == %{}, do: nil, else: abandon_changes_confirmation_text())

  defp assign_form_changeset(socket, changeset, form_error \\ nil) do
    socket |> assign(changeset: changeset, form_error: form_error)
  end
end
