defmodule EpicenterWeb.ContactInvestigationDiscontinueLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Ecto.Changeset
  alias Epicenter.AuditLog
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias EpicenterWeb.Form

  def mount(%{"contact_investigation_id" => contact_investigation_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    contact_investigation = Cases.get_contact_investigation(contact_investigation_id) |> Cases.preload_exposed_person()

    person = contact_investigation.exposed_person

    socket
    |> assign_defaults()
    |> assign_page_title("Discontinue Contact Investigation")
    |> assign(contact_investigation: contact_investigation)
    |> assign(changeset: Cases.change_contact_investigation(contact_investigation, %{}))
    |> assign(person: person)
    |> ok()
  end

  def handle_event("change", %{"contact_investigation" => params}, socket) do
    changeset = Cases.change_contact_investigation(socket.assigns.contact_investigation, params)

    socket
    |> assign(:changeset, changeset)
    |> noreply()
  end

  def handle_event("save", %{"contact_investigation" => params}, socket) do
    params = Map.put(params, "interview_discontinued_at", DateTime.utc_now())

    with {:ok, _} <-
           socket.assigns.changeset
           |> Changeset.cast(params, [:interview_discontinue_reason])
           |> Changeset.validate_required([:interview_discontinue_reason])
           |> Changeset.apply_action(:update) do
      Cases.update_contact_investigation(
        socket.assigns.contact_investigation,
        {params,
         %AuditLog.Meta{
           author_id: socket.assigns.current_user.id,
           reason_action: Revision.update_contact_investigation_action(),
           reason_event: Revision.discontinue_contact_investigation_event()
         }}
      )

      socket
      |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person)}#contact-investigations")
      |> noreply()
    else
      {:error, changeset} ->
        socket |> assign(changeset: changeset) |> noreply()
    end
  end

  # # #

  defp reasons(_) do
    ["Unable to reach", "Another contact investigation already underway", "Transferred to another jurisdiction", "Deceased"]
  end

  defp discontinue_form_builder(changeset) do
    Form.new(changeset)
    |> Form.line(fn line ->
      line
      |> Form.radio_button_list(:interview_discontinue_reason, "Reason", reasons(nil),
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
