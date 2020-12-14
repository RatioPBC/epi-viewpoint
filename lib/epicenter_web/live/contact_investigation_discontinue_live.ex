defmodule EpicenterWeb.ContactInvestigationDiscontinueLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]
  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Ecto.Changeset
  alias Epicenter.AuditLog
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias EpicenterWeb.Form

  def mount(%{"exposure_id" => exposure_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    exposure = Cases.get_contact_investigation(exposure_id) |> Cases.preload_exposed_person()

    person = exposure.exposed_person

    socket
    |> assign_page_title("Discontinue Contact Investigation")
    |> assign(exposure: exposure)
    |> assign(changeset: Cases.change_contact_investigation(exposure, %{}))
    |> assign(person: person)
    |> ok()
  end

  def handle_event("change", %{"exposure" => params}, socket) do
    changeset = Cases.change_contact_investigation(socket.assigns.exposure, params)

    socket
    |> assign(:changeset, changeset)
    |> noreply()
  end

  def handle_event("save", %{"exposure" => params}, socket) do
    params = Map.put(params, "interview_discontinued_at", DateTime.utc_now())

    with {:ok, _} <-
           socket.assigns.changeset
           |> Changeset.cast(params, [:interview_discontinue_reason])
           |> Changeset.validate_required([:interview_discontinue_reason])
           |> Changeset.apply_action(:update) do
      Cases.update_contact_investigation(
        socket.assigns.exposure,
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

  defp confirmation_prompt(changeset) do
    if changeset.changes == %{}, do: nil, else: abandon_changes_confirmation_text()
  end
end
