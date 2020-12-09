defmodule EpicenterWeb.ContactInvestigationStartInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]
  import EpicenterWeb.Forms.StartInterviewForm, only: [start_interview_form_builder: 2]
  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Forms.StartInterviewForm

  def mount(%{"exposure_id" => exposure_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    exposure = exposure_id |> Cases.get_exposure() |> Cases.preload_exposed_person()
    person = exposure.exposed_person |> Cases.preload_demographics()

    socket
    |> assign_page_title("Start Contact Investigation")
    |> assign(:confirmation_prompt, nil)
    |> assign_form_changeset(StartInterviewForm.changeset(exposure, %{}))
    |> assign(exposure: exposure)
    |> assign(person: person)
    |> ok()
  end

  def handle_event("change", %{"start_interview_form" => params}, socket) do
    new_changeset = StartInterviewForm.changeset(socket.assigns.exposure, params)
    socket |> assign(:confirmation_prompt, confirmation_prompt(new_changeset)) |> noreply()
  end

  def handle_event("save", %{"start_interview_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- StartInterviewForm.changeset(socket.assigns.exposure, params),
         {:form, {:ok, cast_investigation_attrs}} <- {:form, StartInterviewForm.investigation_attrs(form_changeset)},
         {:exposure, {:ok, _exposure}} <-
           {:exposure, update_exposure(socket, cast_investigation_attrs)} do
      socket |> redirect_to_profile_page() |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:case_investigation, {:error, _}} ->
        socket |> assign_form_changeset(StartInterviewForm.changeset(socket.assigns.exposure, params), "An unexpected error occurred") |> noreply()
    end
  end

  # # #

  def assign_form_changeset(socket, form_changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: form_changeset, form_error: form_error)

  defp redirect_to_profile_page(socket),
    do: socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person)}#contact-investigations")

  defp update_exposure(socket, params) do
    Cases.update_exposure(
      socket.assigns.exposure,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_exposure_action(),
         reason_event: AuditLog.Revision.start_interview_event()
       }}
    )
  end

  defp confirmation_prompt(changeset),
    do: if(changeset.changes == %{}, do: nil, else: abandon_changes_confirmation_text())
end
