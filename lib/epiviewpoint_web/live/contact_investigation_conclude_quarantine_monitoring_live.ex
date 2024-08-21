defmodule EpiViewpointWeb.ContactInvestigationConcludeQuarantineMonitoringLive do
  use EpiViewpointWeb, :live_view

  import EpiViewpointWeb.IconView, only: [back_icon: 0]
  import EpiViewpointWeb.LiveHelpers, only: [assign_defaults: 1, authenticate_user: 2, noreply: 1, ok: 1]
  import EpiViewpointWeb.ConfirmationModal, only: [confirmation_prompt: 1]

  alias EpiViewpoint.AuditLog
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.ContactInvestigations.ContactInvestigation
  alias EpiViewpointWeb.Form

  defmodule ConcludeQuarantineMonitoringForm do
    use Ecto.Schema

    import Ecto.Changeset

    @clock Application.compile_env(:epiviewpoint, :clock)

    @required_attrs ~w{reason}a
    @optional_attrs ~w{}a
    @primary_key false
    embedded_schema do
      field :reason, :string
    end

    def changeset(contact_investigation, attrs) do
      %ConcludeQuarantineMonitoringForm{reason: contact_investigation.quarantine_conclusion_reason}
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
    end

    def form_changeset_to_model_attrs(%Ecto.Changeset{} = form_changeset, %{quarantine_concluded_at: quarantine_concluded_at}) do
      quarantine_concluded_at = quarantine_concluded_at || @clock.utc_now()

      case apply_action(form_changeset, :create) do
        {:ok, form} -> {:ok, %{quarantine_conclusion_reason: form.reason, quarantine_concluded_at: quarantine_concluded_at}}
        other -> other
      end
    end
  end

  def mount(%{"id" => contact_investigation_id}, session, socket) do
    socket = socket |> authenticate_user(session)

    contact_investigation =
      ContactInvestigations.get(contact_investigation_id, socket.assigns.current_user)
      |> ContactInvestigations.preload_exposed_person()

    socket
    |> assign_defaults()
    |> assign_page_heading(contact_investigation)
    |> assign(:confirmation_prompt, nil)
    |> assign(:contact_investigation, contact_investigation)
    |> assign(:form_changeset, ConcludeQuarantineMonitoringForm.changeset(contact_investigation, %{}))
    |> ok()
  end

  def handle_event("change", %{"conclude_quarantine_monitoring_form" => params}, socket) do
    new_changeset = ConcludeQuarantineMonitoringForm.changeset(socket.assigns.contact_investigation, params)
    socket |> assign(confirmation_prompt: confirmation_prompt(new_changeset), form_changeset: new_changeset) |> noreply()
  end

  def handle_event("save", full_params, socket) do
    params = full_params |> Map.get("conclude_quarantine_monitoring_form", %{})

    with %Ecto.Changeset{} = form_changeset <- ConcludeQuarantineMonitoringForm.changeset(socket.assigns.contact_investigation, params),
         {:form, {:ok, model_attrs}} <-
           {:form, ConcludeQuarantineMonitoringForm.form_changeset_to_model_attrs(form_changeset, socket.assigns.contact_investigation)},
         {:contact_investigation, {:ok, _contact_investigation}} <-
           {:contact_investigation,
            ContactInvestigations.update(
              socket.assigns.contact_investigation,
              {model_attrs,
               %AuditLog.Meta{
                 author_id: socket.assigns.current_user.id,
                 reason_action: AuditLog.Revision.update_contact_investigation_action(),
                 reason_event: AuditLog.Revision.conclude_contact_investigation_quarantine_monitoring_event()
               }}
            )} do
      socket
      |> push_navigate(to: ~p"/people/#{socket.assigns.contact_investigation.exposed_person}/#contact-investigations")
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign(:form_changeset, form_changeset) |> noreply()
    end
  end

  def conclude_quarantine_monitoring_form_builder(form) do
    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :reason, "Reason", ContactInvestigation.text_field_values(:quarantine_conclusion_reason), span: 5))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  # # #

  defp assign_page_heading(socket, %ContactInvestigation{quarantine_concluded_at: nil}),
    do: assign(socket, page_heading: "Conclude quarantine monitoring")

  defp assign_page_heading(socket, %ContactInvestigation{}), do: assign(socket, page_heading: "Edit conclude quarantine monitoring")
end
