defmodule EpicenterWeb.CaseInvestigationIsolationMonitoringLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, authenticate_user: 2, ok: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Format
  alias EpicenterWeb.Form

  defmodule IsolationMonitoringForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :date_ended, :string
      field :date_started, :string
    end

    def changeset(%CaseInvestigation{} = case_investigation),
      do: cast(%IsolationMonitoringForm{date_started: isolation_date_started(case_investigation), date_ended: "01/11/2020"}, %{}, [], [])

    def isolation_date_started(%CaseInvestigation{symptom_onset_date: nil} = case_investigation) do
      case_investigation |> Cases.preload_initiating_lab_result() |> Map.get(:initiating_lab_result) |> Map.get(:sampled_on) |> Format.date()
    end

    def isolation_date_started(%CaseInvestigation{symptom_onset_date: symptom_onset_date}) do
      symptom_onset_date |> Format.date()
    end
  end

  def mount(%{"id" => case_investigation_id}, session, socket) do
    case_investigation = case_investigation_id |> Cases.get_case_investigation()

    socket
    |> assign_page_title(" Case Investigation Isolation Monitoring")
    |> authenticate_user(session)
    |> assign(:case_investigation, case_investigation)
    |> assign(:form_changeset, IsolationMonitoringForm.changeset(case_investigation))
    |> ok()
  end

  def isolation_monitoring_form_builder(form) do
    Form.new(form)
    |> Form.line(&Form.date_field(&1, :date_started, "Isolation start date", span: 3, explanation_text: "Onset date: MM/DD/YYYY"))
    |> Form.line(&Form.date_field(&1, :date_ended, "Isolation end date", span: 3, explanation_text: "Recommended length: 10 days"))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end
end
