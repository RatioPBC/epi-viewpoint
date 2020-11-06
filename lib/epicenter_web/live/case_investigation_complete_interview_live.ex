defmodule EpicenterWeb.CaseInvestigationCompleteInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.CompleteInterviewForm
  alias EpicenterWeb.PresentationConstants

  def mount(%{"id" => case_investigation_id}, session, socket) do
    case_investigation = case_investigation_id |> Cases.get_case_investigation()
    person = case_investigation |> Cases.preload_person() |> Map.get(:person)

    socket
    |> authenticate_user(session)
    |> assign_page_title("Complete interview")
    |> assign(:case_investigation, case_investigation)
    |> assign(:confirmation_prompt, nil)
    |> assign(:form_changeset, CompleteInterviewForm.changeset(case_investigation))
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
      |> Form.select(:time_completed_am_pm, "", time_completed_am_pm_options(), span: 1)
      |> Form.content_div(timezone.abbreviation, row: 3)
    end)
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  def handle_event("change", %{"complete_interview_form" => params}, socket) do
    new_changeset = CompleteInterviewForm.changeset(socket.assigns.case_investigation) |> CompleteInterviewForm.cast(params)

    socket |> assign(:confirmation_prompt, confirmation_prompt(new_changeset)) |> noreply()
  end

  def handle_event("save", %{"complete_interview_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- CompleteInterviewForm.changeset(params),
         {:form, {:ok, cast_investigation_attrs}} <- {:form, CompleteInterviewForm.case_investigation_attrs(form_changeset)},
         {:case_investigation, {:ok, _case_investigation}} <- {:case_investigation, update_case_investigation(socket, cast_investigation_attrs)} do
      socket |> redirect_to_profile_page() |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:case_investigation, {:error, _}} ->
        socket |> assign_form_changeset(CompleteInterviewForm.changeset(params), "An unexpected error occurred") |> noreply()
    end
  end

  defp update_case_investigation(socket, params) do
    Cases.update_case_investigation(
      socket.assigns.case_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_case_investigation_action(),
         reason_event: AuditLog.Revision.discontinue_pending_case_interview_event()
       }}
    )
  end

  defp assign_form_changeset(socket, form_changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: form_changeset, form_error: form_error)

  defp redirect_to_profile_page(socket),
    do: socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person)}#case-investigations")

  defp time_completed_am_pm_options(),
    do: ["AM", "PM"]

  defp confirmation_prompt(changeset),
    do: if(changeset.changes == %{}, do: nil, else: abandon_changes_confirmation_text())
end
