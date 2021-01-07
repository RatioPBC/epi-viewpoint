defmodule EpicenterWeb.CaseInvestigationIsolationMonitoringLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpicenterWeb.IconView, only: [back_icon: 0]

  import EpicenterWeb.LiveHelpers,
    only: [
      assign_case_investigation: 2,
      assign_defaults: 1,
      assign_form_changeset: 2,
      assign_form_changeset: 3,
      assign_page_title: 2,
      authenticate_user: 2,
      noreply: 1,
      ok: 1
    ]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.DateParser
  alias EpicenterWeb.Format
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

    def changeset(case_investigation, attrs) do
      {start_date, end_date} = isolation_dates(case_investigation)

      %IsolationMonitoringForm{date_ended: end_date, date_started: start_date}
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> Validation.validate_date(:date_started)
      |> Validation.validate_date(:date_ended)
    end

    def form_changeset_to_model_attrs(%Ecto.Changeset{} = form_changeset) do
      case apply_action(form_changeset, :create) do
        {:ok, form} ->
          {:ok,
           %{
             isolation_monitoring_starts_on: form |> Map.get(:date_started) |> DateParser.parse_mm_dd_yyyy!(),
             isolation_monitoring_ends_on: form |> Map.get(:date_ended) |> DateParser.parse_mm_dd_yyyy!()
           }}

        other ->
          other
      end
    end

    defp isolation_dates(%CaseInvestigation{isolation_monitoring_starts_on: nil, isolation_monitoring_ends_on: nil} = case_investigation) do
      suggested_isolation_dates(case_investigation)
    end

    defp isolation_dates(%CaseInvestigation{isolation_monitoring_starts_on: start_date, isolation_monitoring_ends_on: end_date}) do
      {Format.date(start_date), Format.date(end_date)}
    end

    defp suggested_isolation_dates(%CaseInvestigation{symptom_onset_on: nil} = case_investigation) do
      start = case_investigation |> Map.get(:initiating_lab_result) |> Map.get(:sampled_on)
      {start |> Format.date(), start |> Date.add(10) |> Format.date()}
    end

    defp suggested_isolation_dates(%CaseInvestigation{symptom_onset_on: symptom_onset_on}) do
      {symptom_onset_on |> Format.date(), symptom_onset_on |> Date.add(10) |> Format.date()}
    end
  end

  def handle_event("change", %{"isolation_monitoring_form" => params}, socket) do
    new_changeset = IsolationMonitoringForm.changeset(socket.assigns.case_investigation, params)
    socket |> assign(confirmation_prompt: confirmation_prompt(new_changeset), form_changeset: new_changeset) |> noreply()
  end

  def handle_event("save", %{"isolation_monitoring_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- IsolationMonitoringForm.changeset(socket.assigns.case_investigation, params),
         {:form, {:ok, model_attrs}} <- {:form, IsolationMonitoringForm.form_changeset_to_model_attrs(form_changeset)},
         {:case_investigation, {:ok, _case_investigation}} <- {:case_investigation, update_case_investigation(socket, model_attrs)} do
      socket
      |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.case_investigation.person)}#case-investigations")
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        # TODO: Better error message
        socket |> assign_form_changeset(form_changeset, "Form error message") |> noreply()
    end
  end

  def isolation_monitoring_form_builder(form, case_investigation) do
    onset_date = case_investigation.symptom_onset_on
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
    case_investigation =
      case_investigation_id
      |> Cases.get_case_investigation()
      |> Cases.preload_initiating_lab_result()
      |> Cases.preload_person()

    socket
    |> assign_defaults()
    |> assign_page_title(" Case Investigation Isolation Monitoring")
    |> authenticate_user(session)
    |> assign_case_investigation(case_investigation)
    |> assign(:confirmation_prompt, nil)
    |> assign_form_changeset(IsolationMonitoringForm.changeset(case_investigation, %{}))
    |> ok()
  end

  # # #

  defp update_case_investigation(socket, params) do
    Cases.update_case_investigation(
      socket.assigns.case_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_case_investigation_action(),
         reason_event: AuditLog.Revision.edit_case_investigation_isolation_monitoring_event()
       }}
    )
  end
end
