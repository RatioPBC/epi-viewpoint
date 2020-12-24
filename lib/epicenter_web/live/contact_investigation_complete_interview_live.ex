defmodule EpicenterWeb.ContactInvestigationCompleteInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_form_changeset: 2, assign_form_changeset: 3, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.CompleteInterviewForm
  alias EpicenterWeb.PresentationConstants

  def mount(%{"id" => contact_investigation_id}, session, socket) do
    contact_investigation = Cases.get_contact_investigation(contact_investigation_id)
    person = contact_investigation |> Cases.preload_exposed_person() |> Map.get(:exposed_person)
    form_changeset = CompleteInterviewForm.changeset(contact_investigation, %{})

    socket
    |> assign_defaults()
    |> assign_page_title("Complete interview")
    |> authenticate_user(session)
    |> assign(:contact_investigation, contact_investigation)
    |> assign_form_changeset(form_changeset)
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

  def handle_event("save", %{"complete_interview_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- CompleteInterviewForm.changeset(socket.assigns.contact_investigation, params),
         {:form, {:ok, contact_investigation_attrs}} <- {:form, CompleteInterviewForm.investigation_attrs(form_changeset)},
         {:contact_investigation, {:ok, _contact_investigation}} <-
           {:contact_investigation, update_contact_investigation(socket, contact_investigation_attrs)} do
      socket |> redirect_to_profile_page() |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:contact_investigation, {:error, _}} ->
        socket
        |> assign_form_changeset(CompleteInterviewForm.changeset(socket.assigns.contact_investigation, params), "An unexpected error occurred")
        |> noreply()
    end
  end

  # # #

  def header_text(%{interview_completed_at: nil}), do: "Complete interview"
  def header_text(%{interview_completed_at: _}), do: "Edit interview"

  defp update_contact_investigation(socket, params) do
    Cases.update_contact_investigation(
      socket.assigns.contact_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_contact_investigation_action(),
         reason_event: AuditLog.Revision.complete_contact_investigation_interview_event()
       }}
    )
  end

  defp redirect_to_profile_page(socket),
    do: socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person)}#contact-investigations")
end
