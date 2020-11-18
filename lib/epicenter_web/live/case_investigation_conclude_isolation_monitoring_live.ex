defmodule EpicenterWeb.CaseInvestigationConcludeIsolationMonitoringLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Form

  defmodule ConcludeIsolationMonitoringForm do
    use Ecto.Schema

    import Ecto.Changeset

    @clock Application.get_env(:epicenter, :clock)

    @required_attrs ~w{reason}a
    @optional_attrs ~w{}a
    @primary_key false
    embedded_schema do
      field :reason, :string
    end

    def changeset(case_investigation, attrs) do
      %ConcludeIsolationMonitoringForm{reason: case_investigation.isolation_conclusion_reason}
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
    end

    def form_changeset_to_model_attrs(%Ecto.Changeset{} = form_changeset, %{isolation_concluded_at: isolation_concluded_at}) do
      isolation_concluded_at = isolation_concluded_at || @clock.utc_now()

      case apply_action(form_changeset, :create) do
        {:ok, form} -> {:ok, %{isolation_conclusion_reason: form.reason, isolation_concluded_at: isolation_concluded_at}}
        other -> other
      end
    end
  end

  def mount(%{"id" => case_investigation_id}, session, socket) do
    case_investigation = Cases.get_case_investigation(case_investigation_id) |> Cases.preload_person()

    socket
    |> assign(:case_investigation, case_investigation)
    |> assign(:confirmation_prompt, nil)
    |> assign(:form_changeset, ConcludeIsolationMonitoringForm.changeset(case_investigation, %{}))
    |> assign(:page_heading, page_heading(case_investigation))
    |> assign(:person, case_investigation.person)
    |> assign_page_title(" Case Investigation Conclude Isolation Monitoring")
    |> authenticate_user(session)
    |> ok()
  end

  def handle_event("change", %{"conclude_isolation_monitoring_form" => params}, socket) do
    new_changeset = ConcludeIsolationMonitoringForm.changeset(socket.assigns.case_investigation, params)
    socket |> assign(:confirmation_prompt, confirmation_prompt(new_changeset)) |> noreply()
  end

  def handle_event("save", full_params, socket) do
    params = full_params |> Map.get("conclude_isolation_monitoring_form", %{})

    with %Ecto.Changeset{} = form_changeset <- ConcludeIsolationMonitoringForm.changeset(socket.assigns.case_investigation, params),
         {:form, {:ok, model_attrs}} <-
           {:form, ConcludeIsolationMonitoringForm.form_changeset_to_model_attrs(form_changeset, socket.assigns.case_investigation)},
         {:case_investigation, {:ok, _case_investigation}} <-
           {:case_investigation,
            Cases.update_case_investigation(
              socket.assigns.case_investigation,
              {model_attrs,
               %AuditLog.Meta{
                 author_id: socket.assigns.current_user.id,
                 reason_action: AuditLog.Revision.update_case_investigation_action(),
                 reason_event: AuditLog.Revision.conclude_case_investigation_isolation_monitoring_event()
               }}
            )} do
      socket |> redirect_to_profile_page() |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign(:form_changeset, form_changeset) |> noreply()
    end
  end

  def conclude_isolation_monitoring_form_builder(form) do
    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :reason, "Reason", CaseInvestigation.text_field_values(:isolation_conclusion_reason), span: 5))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  # # #

  defp confirmation_prompt(changeset),
    do: if(changeset.changes == %{}, do: nil, else: abandon_changes_confirmation_text())

  def page_heading(case_investigation) do
    case CaseInvestigation.isolation_monitoring_status(case_investigation) do
      :concluded -> "Edit conclude isolation monitoring"
      _ -> "Conclude isolation monitoring"
    end
  end

  defp redirect_to_profile_page(socket),
    do: socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person)}#case-investigations")
end
