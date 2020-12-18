defmodule EpicenterWeb.ContactInvestigationQuarantineMonitoringLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, ok: 1]

  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Format
  alias EpicenterWeb.Forms.QuarantineMonitoringForm

  defmodule QuarantineMonitoringForm do
    use Ecto.Schema

    import Ecto.Changeset

    alias Epicenter.Cases.ContactInvestigation
    alias Epicenter.DateParser
    alias Epicenter.Validation
    alias EpicenterWeb.Format

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
      suggested_isolation_dates(contact_investigation)
    end

    defp isolation_dates(%ContactInvestigation{quarantine_monitoring_starts_on: start_date, quarantine_monitoring_ends_on: end_date}) do
      {Format.date(start_date), Format.date(end_date)}
    end

    defp suggested_isolation_dates(%ContactInvestigation{exposed_on: exposed_on}) do
      {exposed_on |> Format.date(), exposed_on |> Date.add(10) |> Format.date()}
    end
  end

  def mount(%{"id" => id}, session, socket) do
    contact_investigation = Cases.get_contact_investigation(id)

    socket
    |> assign_defaults()
    |> assign_page_title(" Contact Investigation Quarantine Monitoring")
    |> authenticate_user(session)
    |> assign(:contact_investigation, contact_investigation)
    |> assign_form_changeset(QuarantineMonitoringForm.changeset(contact_investigation, %{}))
    |> ok()
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

  defp assign_form_changeset(socket, form_changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: form_changeset, form_error: form_error)
end
