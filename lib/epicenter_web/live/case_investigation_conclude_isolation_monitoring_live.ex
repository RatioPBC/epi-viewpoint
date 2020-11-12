defmodule EpicenterWeb.CaseInvestigationConcludeIsolationMonitoringLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, authenticate_user: 2, ok: 1]

  alias EpicenterWeb.Form

  defmodule ConcludeIsolationMonitoringForm do
    use Ecto.Schema

    import Ecto.Changeset

    @required_attrs ~w{reason}a
    @optional_attrs ~w{}a
    @primary_key false
    embedded_schema do
      field :reason, :string
    end

    def changeset(_, attrs) do
      %ConcludeIsolationMonitoringForm{}
      |> cast(attrs, @required_attrs ++ @optional_attrs)
    end
  end

  def mount(%{"id" => _case_investigation_id}, session, socket) do
    socket
    |> assign_page_title(" Case Investigation Conclude Isolation Monitoring")
    |> assign(:form_changeset, ConcludeIsolationMonitoringForm.changeset(:foo, %{}))
    |> authenticate_user(session)
    |> ok()
  end

  def conclude_isolation_monitoring_form_builder(form) do
    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :reason, "Reason", conclude_reason_options(), span: 5))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  defp conclude_reason_options() do
    [
      {"Successfully completed isolation period", "successfully_completed"},
      {"Person unable to isolate", "unable_to_isolate"},
      {"Refused to cooperate", "refused_to_cooperate"},
      {"Lost to follow up", "lost_to_follow_up"},
      {"Transferred to another jurisdiction", "transferred"},
      {"Deceased", "deceased"}
    ]
  end
end
