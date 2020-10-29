defmodule EpicenterWeb.CaseInvestigationDiscontinueLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Form

  def mount(%{"id" => person_id, "case_investigation_id" => case_investigation_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    person = Cases.get_person(person_id)
    case_investigation = Cases.get_case_investigation(case_investigation_id)

    socket
    |> assign_page_title("Discontinue Case Investigation")
    |> assign(case_investigation: case_investigation)
    |> assign(changeset: Cases.change_case_investigation(case_investigation, %{}))
    |> assign(person: person)
    |> ok()
  end

  def handle_event("save", %{"case_investigation" => params}, socket) do
    params = Map.put(params, "discontinued_at", DateTime.utc_now())
    with {:ok, _} <-
           Cases.update_case_investigation(
             socket.assigns.case_investigation,
             {params,
              %AuditLog.Meta{
                author_id: socket.assigns.current_user.id,
                reason_action: AuditLog.Revision.update_case_investigation_action(),
                reason_event: AuditLog.Revision.discontinue_pending_case_interview_event()
              }}
           ) do
      socket
      |> push_redirect(to: Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person))
      |> noreply()
    end
  end

  def reasons() do
    ["Unable to reach", "Transferred to another jurisdiction", "Deceased"]
  end

  # # #

  def discontinue_form_builder(changeset) do
    Form.new(changeset)
    |> Form.line(fn line ->
      line
      |> Form.radio_button_list(:discontinue_reason, "Reason", reasons(), [other: "Other"], 8)
    end)
    |> Form.line(fn line ->
      line
      |> Form.save_button()
    end)
    |> Form.safe()
  end
end
