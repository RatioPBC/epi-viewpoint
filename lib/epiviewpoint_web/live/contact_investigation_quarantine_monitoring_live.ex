defmodule EpiViewpointWeb.ContactInvestigationQuarantineMonitoringLive do
  use EpiViewpointWeb, :live_view

  import EpiViewpointWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpiViewpointWeb.IconView, only: [back_icon: 0]

  import EpiViewpointWeb.LiveHelpers,
    only: [
      assign_defaults: 1,
      assign_form_changeset: 2,
      assign_form_changeset: 3,
      assign_page_title: 2,
      authenticate_user: 2,
      noreply: 1,
      ok: 1
    ]

  alias EpiViewpoint.AuditLog
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpointWeb.Form
  alias EpiViewpointWeb.Format
  alias EpiViewpointWeb.Forms.QuarantineMonitoringForm

  defmodule QuarantineMonitoringForm do
    use Ecto.Schema

    import Ecto.Changeset

    alias EpiViewpoint.ContactInvestigations.ContactInvestigation
    alias EpiViewpoint.DateParser
    alias EpiViewpoint.Validation
    alias EpiViewpointWeb.Format

    @required_attrs ~w{date_ended date_started}a
    @optional_attrs ~w{}a
    @primary_key false
    embedded_schema do
      field :date_ended, :string
      field :date_started, :string
    end

    def changeset(contact_investigation, attrs) do
      {start_date, end_date} = isolation_dates(contact_investigation)

      %QuarantineMonitoringForm{date_ended: end_date, date_started: start_date}
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
      |> Validation.validate_date(:date_started)
      |> Validation.validate_date(:date_ended)
    end

    def form_changeset_to_model_attrs(%Ecto.Changeset{} = form_changeset) do
      case apply_action(form_changeset, :create) do
        {:ok, form} ->
          {:ok,
           %{
             quarantine_monitoring_starts_on: form |> Map.get(:date_started) |> DateParser.parse_mm_dd_yyyy!(),
             quarantine_monitoring_ends_on: form |> Map.get(:date_ended) |> DateParser.parse_mm_dd_yyyy!()
           }}

        other ->
          other
      end
    end

    defp isolation_dates(%ContactInvestigation{quarantine_monitoring_starts_on: nil, quarantine_monitoring_ends_on: nil} = contact_investigation) do
      {Format.date(contact_investigation.exposed_on), nil}
    end

    defp isolation_dates(%ContactInvestigation{quarantine_monitoring_starts_on: starts_on, quarantine_monitoring_ends_on: ends_on}) do
      {Format.date(starts_on), Format.date(ends_on)}
    end
  end

  def mount(%{"id" => id}, session, socket) do
    socket = socket |> authenticate_user(session)
    contact_investigation = ContactInvestigations.get(id, socket.assigns.current_user) |> ContactInvestigations.preload_exposed_person()

    socket
    |> assign_defaults()
    |> assign_page_title(" Contact Investigation Quarantine Monitoring")
    |> assign(:confirmation_prompt, nil)
    |> assign(:contact_investigation, contact_investigation)
    |> assign_form_changeset(QuarantineMonitoringForm.changeset(contact_investigation, %{}))
    |> ok()
  end

  def handle_event("change", %{"quarantine_monitoring_form" => params}, socket) do
    new_changeset = QuarantineMonitoringForm.changeset(socket.assigns.contact_investigation, params)

    socket |> assign(confirmation_prompt: confirmation_prompt(new_changeset)) |> assign_form_changeset(new_changeset) |> noreply()
  end

  def handle_event("save", %{"quarantine_monitoring_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- QuarantineMonitoringForm.changeset(socket.assigns.contact_investigation, params),
         {:form, {:ok, model_attrs}} <- {:form, QuarantineMonitoringForm.form_changeset_to_model_attrs(form_changeset)},
         {:contact_investigation, {:ok, _contact_investigation}} <- {:contact_investigation, update_contact_investigation(socket, model_attrs)} do
      socket
      |> push_navigate(to: ~p"/people/#{socket.assigns.contact_investigation.exposed_person}/#case-investigations")
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset, "Form error message") |> noreply()
    end
  end

  def quarantine_monitoring_form_builder(form, contact_investigation) do
    Form.new(form)
    |> Form.line(
      &Form.date_field(&1, :date_started, "Quarantine start date",
        span: 3,
        explanation_text: "Exposure date: #{Format.date(contact_investigation.exposed_on)}",
        attributes: [data_role: "exposed-date"]
      )
    )
    |> Form.line(
      &Form.date_field(&1, :date_ended, "Quarantine end date",
        span: 3,
        explanation_text: "Recommended length: 14 days",
        attributes: [data_role: "recommended-length"]
      )
    )
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  # # #

  defp page_title(%{quarantine_monitoring_starts_on: nil, quarantine_monitoring_ends_on: nil}), do: "Add quarantine dates"
  defp page_title(_), do: "Edit quarantine dates"

  defp update_contact_investigation(socket, params) do
    ContactInvestigations.update(
      socket.assigns.contact_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_contact_investigation_action(),
         reason_event: AuditLog.Revision.edit_contact_investigation_quarantine_monitoring_event()
       }}
    )
  end
end
