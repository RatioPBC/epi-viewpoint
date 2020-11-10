defmodule EpicenterWeb.CaseInvestigationIsolationMonitoringLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Format
  alias Epicenter.Validation
  alias EpicenterWeb.Form

  defmodule IsolationMonitoringForm do
    use Ecto.Schema

    import Ecto.Changeset

    @required_attrs ~w{date_ended date_started}a
    @optional_attrs ~w{}a
    @primary_key false
    embedded_schema do
      field :date_ended, :string
      field :date_started, :string
    end

    def attrs_to_form_changeset(attrs) do
      %IsolationMonitoringForm{}
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> Validation.validate_date(:date_started)
      |> Validation.validate_date(:date_ended)
    end

    def isolation_dates(%CaseInvestigation{symptom_onset_date: nil} = case_investigation) do
      start = case_investigation |> Cases.preload_initiating_lab_result() |> Map.get(:initiating_lab_result) |> Map.get(:sampled_on)
      {start |> Format.date(), start |> Date.add(10) |> Format.date()}
    end

    def isolation_dates(%CaseInvestigation{symptom_onset_date: symptom_onset_date}) do
      {symptom_onset_date |> Format.date(), symptom_onset_date |> Date.add(10) |> Format.date()}
    end

    def form_changeset_to_model_attrs(%Ecto.Changeset{} = form_changeset) do
      case apply_action(form_changeset, :create) do
        {:ok, form} -> {:ok, form |> Map.from_struct()}
        other -> other
      end
    end

    def model_to_form_changeset(%CaseInvestigation{} = case_investigation) do
      {date_started, date_ended} = isolation_dates(case_investigation)
      attrs_to_form_changeset(%{date_started: date_started, date_ended: date_ended})
    end
  end

  def handle_event("save", %{"isolation_monitoring_form" => params}, socket) do
    save_and_redirect(socket, params)
  end

  def isolation_monitoring_form_builder(form, case_investigation) do
    onset_date = case_investigation.symptom_onset_date
    sampled_date = case_investigation.initiating_lab_result.sampled_on

    explanation_text =
      Enum.join(
        [
          "Onset date: #{if(onset_date, do: Format.date(onset_date), else: "Unavailable")}",
          "Positive lab sample: #{if(sampled_date, do: Format.date(sampled_date), else: "Unavailable")}"
        ],
        "\n"
      )

    Form.new(form)
    |> Form.line(
      &Form.date_field(&1, :date_started, "Isolation start date",
        span: 3,
        explanation_text: explanation_text,
        attributes: [data_role: "onset-date"]
      )
    )
    |> Form.line(&Form.date_field(&1, :date_ended, "Isolation end date", span: 3, explanation_text: "Recommended length: 10 days"))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  def mount(%{"id" => case_investigation_id}, session, socket) do
    case_investigation = case_investigation_id |> Cases.get_case_investigation() |> Cases.preload_initiating_lab_result()

    socket
    |> assign_page_title(" Case Investigation Isolation Monitoring")
    |> authenticate_user(session)
    |> assign(:case_investigation, case_investigation)
    |> assign_form_changeset(IsolationMonitoringForm.model_to_form_changeset(case_investigation))
    |> ok()
  end

  # # #

  defp assign_form_changeset(socket, form_changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: form_changeset, form_error: form_error)

  defp save_and_redirect(socket, params) do
    with %Ecto.Changeset{} = form_changeset <- IsolationMonitoringForm.attrs_to_form_changeset(params),
         {:form, {:ok, _model_attrs}} <- {:form, IsolationMonitoringForm.form_changeset_to_model_attrs(form_changeset)} do
      socket |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset, "Form error message") |> noreply()
    end
  end
end
