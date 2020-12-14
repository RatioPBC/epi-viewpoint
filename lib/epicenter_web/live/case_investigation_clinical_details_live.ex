defmodule EpicenterWeb.CaseInvestigationClinicalDetailsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]
  import EpicenterWeb.Presenters.CaseInvestigationPresenter, only: [symptoms_options: 0]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
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
      field :symptom_onset_on, :string
      field :symptoms, {:array, :string}
    end

    @required_attrs ~w{}a
    @optional_attrs ~w{clinical_status symptom_onset_on symptoms}a

    def changeset(%CaseInvestigation{} = case_investigation, attrs \\ %{}) do
      %ClinicalDetailsForm{
        clinical_status: case_investigation.clinical_status,
        symptoms: case_investigation.symptoms,
        symptom_onset_on: Format.date(case_investigation.symptom_onset_on)
      }
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> Validation.validate_date(:symptom_onset_on)
    end

    def case_investigation_attrs(%Ecto.Changeset{} = changeset) do
      case apply_action(changeset, :update) do
        {:ok, clinical_details_form} -> {:ok, case_investigation_attrs(clinical_details_form)}
        other -> other
      end
    end

    def case_investigation_attrs(%ClinicalDetailsForm{} = clinical_details_form) do
      {:ok, symptom_onset_on} = convert_symptom_onset_date(clinical_details_form)

      %{
        clinical_status: clinical_details_form.clinical_status,
        symptom_onset_on: symptom_onset_on,
        symptoms: clinical_details_form.symptoms
      }
    end

    defp convert_symptom_onset_date(attrs) do
      date = attrs |> Map.get(:symptom_onset_on)
      DateParser.parse_mm_dd_yyyy(date)
    end
  end

  def mount(%{"id" => id}, session, socket) do
    case_investigation = id |> Cases.get_case_investigation() |> Cases.preload_initiating_lab_result() |> Cases.preload_person()

    socket
    |> authenticate_user(session)
    |> assign_page_title(" Case Investigation Clinical Details")
    |> assign(:form_changeset, ClinicalDetailsForm.changeset(case_investigation))
    |> assign(:case_investigation, case_investigation)
    |> assign(:confirmation_prompt, nil)
    |> ok()
  end

  def clinical_details_form_builder(form, case_investigation) do
    symptom_onset_on_explanation_text =
      "If asymptomatic, date of first positive test (#{Format.date(case_investigation.initiating_lab_result.sampled_on)})"

    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :clinical_status, "Clinical Status", CaseInvestigation.text_field_values(:clinical_status), span: 5))
    |> Form.line(&Form.date_field(&1, :symptom_onset_on, "Symptom onset date*", explanation_text: symptom_onset_on_explanation_text, span: 5))
    |> Form.line(&Form.checkbox_list(&1, :symptoms, "Symptoms", symptoms_options(), span: 5))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  def handle_event("change", %{"clinical_details_form" => params}, socket) do
    params =
      if Map.has_key?(params, :symptoms) do
        params
      else
        Map.put(params, "symptoms", [])
      end

    new_changeset = ClinicalDetailsForm.changeset(socket.assigns.case_investigation, params)

    socket |> assign(confirmation_prompt: confirmation_prompt(new_changeset), form_changeset: new_changeset) |> noreply()
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
             socket.assigns.case_investigation,
             params
           ),
         {:form, {:ok, cast_investigation_attrs}} <- {:form, ClinicalDetailsForm.case_investigation_attrs(form_changeset)},
         {:case_investigation, {:ok, _case_investigation}} <- {:case_investigation, update_case_investigation(socket, cast_investigation_attrs)} do
      socket |> redirect_to_profile_page() |> noreply()
    else
      {:form, {:error, form_changeset}} ->
        socket |> assign(:form_changeset, form_changeset) |> noreply()
    end
  end

  defp update_case_investigation(socket, params) do
    Cases.update_case_investigation(
      socket.assigns.case_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_case_investigation_action(),
         reason_event: AuditLog.Revision.edit_case_interview_clinical_details_event()
       }}
    )
  end

  defp redirect_to_profile_page(socket) do
    person = socket.assigns.case_investigation.person
    socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, person)}#case-investigations")
  end
end
