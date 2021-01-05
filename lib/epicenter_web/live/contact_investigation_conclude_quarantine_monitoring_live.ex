defmodule EpicenterWeb.ContactInvestigationConcludeQuarantineMonitoringLive do
  use EpicenterWeb, :live_view
  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, authenticate_user: 2, ok: 1]

  alias Epicenter.ContactInvestigations
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias EpicenterWeb.Form

  defmodule ConcludeQuarantineMonitoringForm do
    use Ecto.Schema

    import Ecto.Changeset

    @required_attrs ~w{reason}a
    @optional_attrs ~w{}a
    @primary_key false
    embedded_schema do
      field :reason, :string
    end

    def changeset(_contact_investigation, attrs) do
      #      %ConcludeQuarantineMonitoringForm{reason: contact_investigation.quarantine_conclusion_reason}
      %ConcludeQuarantineMonitoringForm{reason: nil}
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
    end
  end

  def mount(%{"id" => contact_investigation_id}, session, socket) do
    contact_investigation = ContactInvestigations.get(contact_investigation_id)

    socket
    |> assign_defaults()
    |> assign(:page_heading, "Conclude quarantine monitoring")
    |> assign(:form_changeset, ConcludeQuarantineMonitoringForm.changeset(contact_investigation, %{}))
    |> authenticate_user(session)
    |> ok()
  end

  def conclude_quarantine_monitoring_form_builder(form) do
    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :reason, "Reason", ContactInvestigation.text_field_values(:quarantine_conclusion_reason), span: 5))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end
end
