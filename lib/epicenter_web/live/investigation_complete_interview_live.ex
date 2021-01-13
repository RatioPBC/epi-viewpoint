defmodule EpicenterWeb.InvestigationCompleteInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpicenterWeb.IconView, only: [back_icon: 0]

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_form_changeset: 2, assign_form_changeset: 3, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.CompleteInterviewForm
  alias EpicenterWeb.PresentationConstants

  def mount(%{"id" => contact_investigation_id}, session, %{assigns: %{live_action: :complete_contact_investigation}} = socket) do
    socket = socket |> authenticate_user(session)

    ContactInvestigations.get(contact_investigation_id, socket.assigns.current_user)
    |> ContactInvestigations.preload_exposed_person()
    |> mount(session, socket)
  end

  def mount(%{"id" => case_investigation_id}, session, %{assigns: %{live_action: :complete_case_investigation}} = socket) do
    socket = socket |> authenticate_user(session)

    Cases.get_case_investigation(case_investigation_id, socket.assigns.current_user)
    |> Cases.preload_person()
    |> mount(session, socket)
  end

  def mount(investigation, _session, socket) do
    form_changeset = CompleteInterviewForm.changeset(investigation, %{})

    socket
    |> assign_defaults()
    |> assign_page_title("Complete interview")
    |> assign_investigation(investigation)
    |> assign(:confirmation_prompt, nil)
    |> assign_form_changeset(form_changeset)
    |> ok()
  end

  def handle_event("change", %{"complete_interview_form" => params}, socket) do
    new_changeset = CompleteInterviewForm.changeset(socket.assigns.investigation, params)

    socket |> assign(confirmation_prompt: confirmation_prompt(new_changeset)) |> assign_form_changeset(new_changeset) |> noreply()
  end

  def handle_event("save", %{"complete_interview_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- CompleteInterviewForm.changeset(socket.assigns.investigation, params),
         {:form, {:ok, case_investigation_attrs}} <- {:form, CompleteInterviewForm.investigation_attrs(form_changeset)},
         {:investigation, {:ok, _investigation}} <- {:investigation, update_case_investigation(socket, case_investigation_attrs)} do
      socket
      |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, get_person(socket.assigns.investigation))}#case-investigations")
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:investigation, {:error, _}} ->
        socket
        |> assign_form_changeset(CompleteInterviewForm.changeset(socket.assigns.investigation, params), "An unexpected error occurred")
        |> noreply()
    end
  end

  # # #

  defp assign_investigation(socket, %Cases.CaseInvestigation{} = investigation) do
    AuditLog.view(socket.assigns.current_user, investigation.person)
    socket |> assign(:investigation, investigation)
  end

  defp assign_investigation(socket, %ContactInvestigations.ContactInvestigation{} = investigation) do
    AuditLog.view(socket.assigns.current_user, investigation.exposed_person)
    socket |> assign(:investigation, investigation)
  end

  defp complete_interview_form_builder(form) do
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

  defp get_person(%Cases.CaseInvestigation{} = investigation), do: investigation.person
  defp get_person(%ContactInvestigations.ContactInvestigation{} = investigation), do: investigation.exposed_person

  defp header_text(%{interview_completed_at: nil}), do: "Complete interview"
  defp header_text(%{interview_completed_at: _}), do: "Edit interview"

  defp update_case_investigation(%{assigns: %{investigation: %Cases.CaseInvestigation{} = investigation}} = socket, params) do
    Cases.complete_case_investigation_interview(investigation, socket.assigns.current_user.id, params)
  end

  defp update_case_investigation(%{assigns: %{investigation: %ContactInvestigations.ContactInvestigation{} = contact_investigation}} = socket, params) do
    ContactInvestigations.complete_interview(contact_investigation, socket.assigns.current_user.id, params)
  end
end
