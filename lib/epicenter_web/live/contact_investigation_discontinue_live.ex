defmodule EpicenterWeb.ContactInvestigationDiscontinueLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Ecto.Changeset
  alias Epicenter.AuditLog
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias EpicenterWeb.Form

  def mount(%{"exposure_id" => exposure_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    exposure = Cases.get_exposure(exposure_id) |> Cases.preload_exposed_person()

    person = exposure.exposed_person

    socket
    |> assign_page_title("Discontinue Contact Investigation")
    |> assign(exposure: exposure)
    |> assign(changeset: Cases.change_exposure(exposure, %{}))
    |> assign(person: person)
    |> ok()
  end

  def handle_event("save", %{"exposure" => params}, socket) do
    params = Map.put(params, "interview_discontinued_at", DateTime.utc_now())

    with {:ok, _} <-
           socket.assigns.changeset
           |> Changeset.cast(params, [:interview_discontinue_reason])
           |> Changeset.validate_required([:interview_discontinue_reason])
           |> Changeset.apply_action(:update) do
      Cases.update_exposure(
        socket.assigns.exposure,
        {params,
         %AuditLog.Meta{
           author_id: socket.assigns.current_user.id,
           reason_action: Revision.update_exposure_action(),
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

  # def reasons("started") do
  #   ["Deceased", "Transferred to another jurisdiction", "Lost to follow up", "Refused to cooperate"]
  # end

  def reasons(_) do
    ["Unable to reach", "Another contact investigation already underway", "Transferred to another jurisdiction", "Deceased"]
  end

  # # #

  def discontinue_form_builder(changeset) do
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
