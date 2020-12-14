defmodule EpicenterWeb.ContactInvestigationStartInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpicenterWeb.Forms.StartInterviewForm, only: [start_interview_form_builder: 2]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Forms.StartInterviewForm

  def mount(%{"contact_investigation_id" => contact_investigation_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    contact_investigation = contact_investigation_id |> Cases.get_contact_investigation() |> Cases.preload_exposed_person()
    person = contact_investigation.exposed_person |> Cases.preload_demographics()

    socket
    |> assign_page_title("Start Contact Investigation")
    |> assign(:confirmation_prompt, nil)
    |> assign_form_changeset(StartInterviewForm.changeset(contact_investigation, %{}))
    |> assign(contact_investigation: contact_investigation)
    |> assign(person: person)
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
      socket |> redirect_to_profile_page() |> noreply()
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

  def assign_form_changeset(socket, form_changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: form_changeset, form_error: form_error)

  defp redirect_to_profile_page(socket),
    do: socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person)}#contact-investigations")

  defp update_contact_investigation(socket, params) do
    Cases.update_contact_investigation(
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
