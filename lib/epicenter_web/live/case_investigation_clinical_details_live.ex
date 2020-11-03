defmodule EpicenterWeb.CaseInvestigationClinicalDetailsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.DateParser
  alias Epicenter.Format
  alias EpicenterWeb.Form

  defmodule ClinicalDetailsForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :clinical_status, :string
      field :symptom_onset_date, :string
      field :symptoms, {:array, :string}
    end

    @required_attrs ~w{}a
    @optional_attrs ~w{clinical_status symptom_onset_date symptoms}a

    def changeset(%CaseInvestigation{} = case_investigation) do
      case_investigation |> case_investigation_form_attrs() |> changeset()
    end

    def changeset(attrs) do
      %ClinicalDetailsForm{}
      |> cast(attrs, @required_attrs ++ @optional_attrs)
    end

    def case_investigation_form_attrs(%CaseInvestigation{} = _case_investigation) do
      # TODO: populate for edit
      %{
        clinical_status: [],
        symptoms: [],
        symptom_onset_date: ""
      }
    end

    def case_investigation_attrs(%Ecto.Changeset{} = changeset) do
      case apply_action(changeset, :update) do
        {:ok, clinical_details_form} -> {:ok, case_investigation_attrs(clinical_details_form)}
        other -> other
      end
    end

    def case_investigation_attrs(%ClinicalDetailsForm{} = clinical_details_form) do
      {:ok, symptom_onset_date} = convert_symptom_onset_date(clinical_details_form)

      %{
        clinical_status: clinical_details_form.clinical_status,
        symptom_onset_date: symptom_onset_date,
        symptoms: clinical_details_form.symptoms
      }
    end

    defp convert_symptom_onset_date(attrs) do
      datestring = attrs |> Map.get(:symptom_onset_date)
      DateParser.parse_mm_dd_yyyy(datestring)
    end
  end

  def mount(%{"id" => id}, session, socket) do
    case_investigation = id |> Cases.get_case_investigation() |> Cases.preload_initiating_lab_result() |> Cases.preload_person()

    socket
    |> authenticate_user(session)
    |> assign_page_title(" Case Investigation Clinical Details")
    |> assign(:form_changeset, ClinicalDetailsForm.changeset(case_investigation))
    |> assign(:case_investigation, case_investigation)
    |> ok()
  end

  def clinical_details_form_builder(form, case_investigation) do
    symptom_onset_date_explanation_text =
      "If asymptomatic, date of first positive test (#{Format.date(case_investigation.initiating_lab_result.sampled_on)})"

    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :clinical_status, "Clinical Status", clinical_statuses(), span: 5))
    |> Form.line(&Form.date_field(&1, :symptom_onset_date, "Symptom onset date*", explanation_text: symptom_onset_date_explanation_text, span: 5))
    |> Form.line(&Form.checkbox_list(&1, :symptoms, "Symptoms", symptoms(), other: "Other", span: 5))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  defp clinical_statuses() do
    [
      {"Unknown", "unknown"},
      {"Symptomatic", "symptomatic"},
      {"Asymptomatic", "asymptomatic"}
    ]
  end

  defp symptoms() do
    [
      {"Fever > 100.4F", "fever"},
      {"Subjective fever (felt feverish)", "subjective_fever"},
      {"Cough", "cough"},
      {"Shortness of breath", "shortness_of_breath"},
      {"Diarrhea/GI", "diarrhea_gi"},
      {"Headache", "headache"},
      {"Muscle ache", "muscle_ache"},
      {"Chills", "chills"},
      {"Sore throat", "sore_throat"},
      {"Vomiting", "vomiting"},
      {"Abdominal pain", "abdominal_pain"},
      {"Nasal congestion", "nasal_congestion"},
      {"Loss of sense of smell", "loss_of_sense_of_smell"},
      {"Loss of sense of taste", "loss_of_sense_of_taste"},
      {"Fatigue", "fatigue"}
    ]
  end

  def handle_event("save", %{"clinical_details_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- ClinicalDetailsForm.changeset(params),
         {:form, {:ok, cast_investigation_attrs}} <- {:form, ClinicalDetailsForm.case_investigation_attrs(form_changeset)},
         {:case_investigation, {:ok, _case_investigation}} <- {:case_investigation, update_case_investigation(socket, cast_investigation_attrs)} do
      socket |> redirect_to_profile_page() |> noreply()
      # TODO: Error handling
      #        else
      #      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
      #        socket |> assign_form_changeset(form_changeset) |> noreply()
      #
      #      {:case_investigation, {:error, _}} ->
      #        socket |> assign_form_changeset(ClinicalDetailsForm.changeset(params), "An unexpected error occurred") |> noreply()
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
