defmodule EpiViewpointWeb.CaseInvestigationStartInterviewLive do
  use EpiViewpointWeb, :live_view

  import EpiViewpointWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpiViewpointWeb.IconView, only: [back_icon: 0]
  import EpiViewpointWeb.Forms.StartInterviewForm, only: [start_interview_form_builder: 2]

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
  alias EpiViewpoint.Cases
  alias EpiViewpointWeb.Forms.StartInterviewForm

  def mount(%{"id" => case_investigation_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    case_investigation = case_investigation_id |> Cases.get_case_investigation(socket.assigns.current_user) |> Cases.preload_person()
    case_investigation = case_investigation |> Map.replace(:person, case_investigation.person |> Cases.preload_demographics())

    socket
    |> assign_defaults()
    |> assign_page_title("Start Case Investigation")
    |> assign_form_changeset(StartInterviewForm.changeset(case_investigation, %{}))
    |> assign(:case_investigation, case_investigation)
    |> ok()
  end

  def handle_event("change", %{"start_interview_form" => params}, socket) do
    changeset = socket.assigns.case_investigation |> StartInterviewForm.changeset(params)
    socket |> assign(form_changeset: changeset) |> noreply()
  end

  def handle_event("save", %{"start_interview_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- StartInterviewForm.changeset(socket.assigns.case_investigation, params),
         {:form, {:ok, cast_investigation_attrs}} <- {:form, StartInterviewForm.investigation_attrs(form_changeset)},
         {:case_investigation, {:ok, _case_investigation}} <- {:case_investigation, update_case_investigation(socket, cast_investigation_attrs)} do
      socket
      |> push_navigate(to: ~p"/people/#{socket.assigns.case_investigation.person}/#case-investigations")
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:case_investigation, {:error, _}} ->
        socket
        |> assign_form_changeset(StartInterviewForm.changeset(socket.assigns.case_investigation, params), "An unexpected error occurred")
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
         reason_event: AuditLog.Revision.start_interview_event()
       }}
    )
  end
end
