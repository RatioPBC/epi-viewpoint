defmodule EpicenterWeb.CaseInvestigationStartInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Format
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.StartInterviewForm
  alias EpicenterWeb.PresentationConstants

  def mount(%{"id" => case_investigation_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    case_investigation = case_investigation_id |> Cases.get_case_investigation() |> Cases.preload_person()
    person = case_investigation.person |> Cases.preload_demographics()

    socket
    |> assign_page_title("Start Case Investigation")
    |> assign_form_changeset(StartInterviewForm.changeset(person))
    |> assign(case_investigation: case_investigation)
    |> assign(person: person)
    |> ok()
  end

  def handle_event("save", %{"start_interview_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- StartInterviewForm.changeset(params),
         {:form, {:ok, cast_investigation_attrs}} <- {:form, StartInterviewForm.case_investigation_attrs(form_changeset)},
         {:case_investigation, {:ok, _case_investigation}} <- {:case_investigation, update_case_investigation(socket, cast_investigation_attrs)} do
      socket |> redirect_to_profile_page() |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:case_investigation, {:error, _}} ->
        socket |> assign_form_changeset(StartInterviewForm.changeset(params), "An unexpected error occurred") |> noreply()
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

  def people_interviewed(person),
    do: [Format.person(person)]

  def time_started_am_pm_options(),
    do: ["AM", "PM"]

  def start_interview_form_builder(form, person) do
    timezone = Timex.timezone(PresentationConstants.presented_time_zone(), Timex.now())

    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :person_interviewed, "Person interviewed", people_interviewed(person), other: "Proxy"))
    |> Form.line(&Form.date_field(&1, :date_started, "Date started"))
    |> Form.line(fn line ->
      line
      |> Form.text_field(:time_started, "Time interviewed")
      |> Form.select(:time_started_am_pm, "", time_started_am_pm_options(), span: 1)
      |> Form.content_div(timezone.abbreviation, row: 3)
    end)
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  # # #

  defp assign_form_changeset(socket, form_changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: form_changeset, form_error: form_error)

  defp redirect_to_profile_page(socket),
    do: socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person)}#case-investigations")
end
