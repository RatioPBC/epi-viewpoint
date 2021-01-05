defmodule EpicenterWeb.ContactInvestigationClinicalDetailsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]
  import EpicenterWeb.Presenters.CaseInvestigationPresenter, only: [symptoms_options: 0]

  alias Epicenter.AuditLog
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.ContactInvestigations
  alias Epicenter.DateParser
  alias EpicenterWeb.Format
  alias Epicenter.Validation
  alias EpicenterWeb.Form

  defmodule ClinicalDetailsForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :clinical_status, :string
      field :exposed_on, :string
      field :symptoms, {:array, :string}
    end

    @required_attrs ~w{}a
    @optional_attrs ~w{clinical_status exposed_on symptoms}a

    def changeset(%ContactInvestigation{} = contact_investigation, attrs \\ %{}) do
      %ClinicalDetailsForm{
        clinical_status: contact_investigation.clinical_status,
        symptoms: contact_investigation.symptoms,
        exposed_on: Format.date(contact_investigation.exposed_on)
      }
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> Validation.validate_date(:exposed_on)
    end

    def contact_investigation_attrs(%Ecto.Changeset{} = changeset) do
      case apply_action(changeset, :update) do
        {:ok, clinical_details_form} -> {:ok, contact_investigation_attrs(clinical_details_form)}
        other -> other
      end
    end

    def contact_investigation_attrs(%ClinicalDetailsForm{} = clinical_details_form) do
      {:ok, exposed_on} = convert_exposed_date(clinical_details_form)

      %{
        clinical_status: clinical_details_form.clinical_status,
        exposed_on: exposed_on,
        symptoms: clinical_details_form.symptoms
      }
    end

    defp convert_exposed_date(attrs) do
      date = attrs |> Map.get(:exposed_on)
      DateParser.parse_mm_dd_yyyy(date)
    end
  end

  def mount(%{"id" => id}, session, socket) do
    contact_investigation = id |> ContactInvestigations.get() |> ContactInvestigations.preload_exposed_person()

    socket
    |> assign_defaults()
    |> authenticate_user(session)
    |> assign_page_title(" Contact Investigation Clinical Details")
    |> assign(:form_changeset, ClinicalDetailsForm.changeset(contact_investigation))
    |> assign(:confirmation_prompt, nil)
    |> assign(:contact_investigation, contact_investigation)
    |> ok()
  end

  def clinical_details_form_builder(form, contact_investigation) do
    exposed_on_explanation_text = "Last together with an initiating index case on #{Format.date(contact_investigation.most_recent_date_together)}"

    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :clinical_status, "Clinical Status", CaseInvestigation.text_field_values(:clinical_status), span: 5))
    |> Form.line(&Form.date_field(&1, :exposed_on, "Exposure date", explanation_text: exposed_on_explanation_text, span: 5))
    |> Form.line(&Form.checkbox_list(&1, :symptoms, "Symptoms", symptoms_options(), span: 5))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  def handle_event("save", %{"clinical_details_form" => params}, socket) do
    any_other_symptoms = params["symptoms_other"] != nil

    params =
      params
      |> Map.put_new("symptoms", [])
      |> Map.update!("symptoms", fn symptoms -> Enum.reject(symptoms, &Euclid.Exists.blank?/1) end)

    prefilled_values =
      symptoms_options()
      |> Enum.map(fn {_label, value} -> value end)

    params =
      if any_other_symptoms do
        params
      else
        %{params | "symptoms" => params["symptoms"] |> Enum.filter(&(&1 in prefilled_values))}
      end

    with %Ecto.Changeset{} = form_changeset <-
           ClinicalDetailsForm.changeset(
             socket.assigns.contact_investigation,
             params
           ),
         {:form, {:ok, contact_investigation_attrs}} <- {:form, ClinicalDetailsForm.contact_investigation_attrs(form_changeset)},
         {:contact_investigation, {:ok, _contact_investigation}} <-
           {:contact_investigation, update_contact_investigation(socket, contact_investigation_attrs)} do
      person = socket.assigns.contact_investigation.exposed_person

      socket
      |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, person)}#contact-investigations")
      |> noreply()
    else
      {:form, {:error, form_changeset}} ->
        socket |> assign(:form_changeset, form_changeset) |> noreply()
    end
  end

  def handle_event("change", %{"clinical_details_form" => params}, socket) do
    params =
      if Map.has_key?(params, "symptoms") do
        params
      else
        Map.put(params, "symptoms", [])
      end

    new_changeset = ClinicalDetailsForm.changeset(socket.assigns.contact_investigation, params)

    socket |> assign(confirmation_prompt: confirmation_prompt(new_changeset), form_changeset: new_changeset) |> noreply()
  end

  defp update_contact_investigation(socket, params) do
    ContactInvestigations.update(
      socket.assigns.contact_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_contact_investigation_action(),
         reason_event: AuditLog.Revision.edit_contact_investigation_clinical_details_event()
       }}
    )
  end
end
