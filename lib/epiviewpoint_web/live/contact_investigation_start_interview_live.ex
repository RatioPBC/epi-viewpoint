defmodule EpiViewpointWeb.ContactInvestigationStartInterviewLive do
  use EpiViewpointWeb, :live_view

  import EpiViewpointWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpiViewpointWeb.Forms.StartInterviewForm, only: [start_interview_form_builder: 2]
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
  alias EpiViewpointWeb.Forms.StartInterviewForm

  def mount(%{"id" => id}, session, socket) do
    socket = socket |> authenticate_user(session)
    contact_investigation = ContactInvestigations.get(id, socket.assigns.current_user) |> ContactInvestigations.preload_exposed_person()

    socket
    |> assign_defaults()
    |> assign_page_title("Start Contact Investigation")
    |> assign(:confirmation_prompt, nil)
    |> assign_form_changeset(StartInterviewForm.changeset(contact_investigation, %{}))
    |> assign(:contact_investigation, contact_investigation)
    |> ok()
  end

  def handle_event("change", %{"start_interview_form" => params}, socket) do
    new_changeset = StartInterviewForm.changeset(socket.assigns.contact_investigation, params)
    socket |> assign(confirmation_prompt: confirmation_prompt(new_changeset), form_changeset: new_changeset) |> noreply()
  end

  def handle_event("save", %{"start_interview_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- StartInterviewForm.changeset(socket.assigns.contact_investigation, params),
         {:form, {:ok, cast_investigation_attrs}} <- {:form, StartInterviewForm.investigation_attrs(form_changeset)},
         {:contact_investigation, {:ok, _contact_investigation}} <-
           {:contact_investigation, update_contact_investigation(socket, cast_investigation_attrs)} do
      socket
      |> push_navigate(to: ~p"/people/#{socket.assigns.contact_investigation.exposed_person}/#contact-investigations")
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:case_investigation, {:error, _}} ->
        socket
        |> assign_form_changeset(StartInterviewForm.changeset(socket.assigns.contact_investigation, params), "An unexpected error occurred")
        |> noreply()
    end
  end

  # # #

  defp update_contact_investigation(socket, params) do
    ContactInvestigations.update(
      socket.assigns.contact_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_contact_investigation_action(),
         reason_event: AuditLog.Revision.start_interview_event()
       }}
    )
  end
end
