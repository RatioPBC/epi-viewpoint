defmodule EpicenterWeb.CaseInvestigationCompleteInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpicenterWeb.IconView, only: [back_icon: 0]

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_form_changeset: 2, assign_form_changeset: 3, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.CompleteInterviewForm
  alias EpicenterWeb.PresentationConstants

  def mount(%{"id" => case_investigation_id}, session, socket) do
    case_investigation = case_investigation_id |> Cases.get_case_investigation()
    person = case_investigation |> Cases.preload_person() |> Map.get(:person)

    socket
    |> assign_defaults()
    |> authenticate_user(session)
    |> assign_page_title("Complete interview")
    |> assign(:case_investigation, case_investigation)
    |> assign(:confirmation_prompt, nil)
    |> assign_form_changeset(CompleteInterviewForm.changeset(case_investigation, %{}))
    |> assign(:person, person)
    |> ok()
  end

  def complete_interview_form_builder(form) do
    timezone = Timex.timezone(PresentationConstants.presented_time_zone(), Timex.now())

    Form.new(form)
    |> Form.line(&Form.date_field(&1, :date_completed, "Date interview completed", span: 3))
    |> Form.line(fn line ->
      line
      |> Form.text_field(:time_completed, "Time interview completed", span: 3)
      |> Form.select(:time_completed_am_pm, "", PresentationConstants.am_pm_options(), span: 1)
      |> Form.content_div(timezone.abbreviation, row: 3)
    end)
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  def handle_event("change", %{"complete_interview_form" => params}, socket) do
    new_changeset = CompleteInterviewForm.changeset(socket.assigns.case_investigation, params)

    socket |> assign(confirmation_prompt: confirmation_prompt(new_changeset)) |> assign_form_changeset(new_changeset) |> noreply()
  end

  def handle_event("save", %{"complete_interview_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- CompleteInterviewForm.changeset(socket.assigns.case_investigation, params),
         {:form, {:ok, case_investigation_attrs}} <- {:form, CompleteInterviewForm.investigation_attrs(form_changeset)},
         {:case_investigation, {:ok, _case_investigation}} <- {:case_investigation, update_case_investigation(socket, case_investigation_attrs)} do
      socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person)}#case-investigations") |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:case_investigation, {:error, _}} ->
        socket
        |> assign_form_changeset(CompleteInterviewForm.changeset(socket.assigns.case_investigation, params), "An unexpected error occurred")
        |> noreply()
    end
  end

  # # #

  defp update_case_investigation(socket, params) do
    Cases.update_case_investigation(
      socket.assigns.case_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_case_investigation_action(),
         reason_event: AuditLog.Revision.complete_case_investigation_interview_event()
       }}
    )
  end
end
