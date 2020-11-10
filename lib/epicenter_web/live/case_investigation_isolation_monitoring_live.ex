defmodule EpicenterWeb.CaseInvestigationIsolationMonitoringLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, authenticate_user: 2, ok: 1]

  alias EpicenterWeb.Form

  defmodule IsolationMonitoringForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :date_ended, :string
      field :date_started, :string
    end

    def changeset(_),
      do: cast(%IsolationMonitoringForm{date_started: "01/01/2020", date_ended: "01/11/2020"}, %{}, [], [])
  end

  def mount(%{"id" => _case_investigation_id}, session, socket) do
    socket
    |> assign_page_title(" Case Investigation Isolation Monitoring")
    |> authenticate_user(session)
    |> assign(:form_changeset, IsolationMonitoringForm.changeset(%{}))
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
