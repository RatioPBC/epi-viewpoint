defmodule EpiViewpointWeb.CaseInvestigationDiscontinueLive do
  use EpiViewpointWeb, :live_view

  import EpiViewpointWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpiViewpointWeb.IconView, only: [back_icon: 0]

  import EpiViewpointWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_form_changeset: 2, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Ecto.Changeset
  alias EpiViewpoint.AuditLog
  alias EpiViewpoint.Cases
  alias EpiViewpointWeb.Form

  def mount(%{"id" => case_investigation_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    case_investigation = case_investigation_id |> Cases.get_case_investigation(socket.assigns.current_user) |> Cases.preload_person()

    socket
    |> assign_defaults()
    |> assign_page_title("Discontinue Case Investigation")
    |> assign(:case_investigation, case_investigation)
    |> assign_form_changeset(Cases.change_case_investigation(case_investigation, %{}))
    |> ok()
  end

  def handle_event("change", %{"case_investigation" => params}, socket) do
    changeset = socket.assigns.case_investigation |> Cases.change_case_investigation(params)
    socket |> assign_form_changeset(changeset) |> noreply()
  end

  def handle_event("save", %{"case_investigation" => params}, socket) do
    params = Map.put(params, "interview_discontinued_at", DateTime.utc_now())

    with {:ok, _} <-
           socket.assigns.form_changeset
           |> Changeset.cast(params, [:interview_discontinue_reason])
           |> Changeset.validate_required([:interview_discontinue_reason])
           |> Changeset.apply_action(:update),
         {:ok, _} <-
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
      |> push_navigate(to: ~p"/people/#{socket.assigns.case_investigation.person}/#case-investigations")
      |> noreply()
    else
      {:error, changeset} ->
        socket |> assign_form_changeset(changeset) |> noreply()
    end
  end

  def reasons("started") do
    ["Deceased", "Transferred to another jurisdiction", "Lost to follow up", "Refused to cooperate"]
  end

  def reasons(_) do
    ["Unable to reach", "Transferred to another jurisdiction", "Deceased"]
  end

  # # #

  def discontinue_form_builder(changeset) do
    Form.new(changeset)
    |> Form.line(fn line ->
      line
      |> Form.radio_button_list(:interview_discontinue_reason, "Reason", reasons(changeset.data.interview_status),
        other: "Other",
        span: 8
      )
    end)
    |> Form.line(fn line ->
      line
      |> Form.save_button()
    end)
    |> Form.safe()
  end
end
