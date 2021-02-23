defmodule EpicenterWeb.AddVisitLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.Format, only: [address: 1]

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, ok: 1, noreply: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.AddVisitForm

  def mount(params, session, socket) do
    socket = socket |> authenticate_user(session)

    case_investigation =
      Cases.get_case_investigation(params["case_investigation_id"], socket.assigns.current_user)
      |> Cases.preload_person()

    place_address = Cases.get_place_address(params["place_address_id"]) |> Cases.preload_place()

    changeset = AddVisitForm.changeset(%AddVisitForm{}, %{})

    socket
    |> assign_defaults()
    |> assign_page_title("Add place visited")
    |> assign(:place_address, place_address)
    |> assign(:case_investigation, case_investigation)
    |> assign(form_changeset: changeset)
    |> ok()
  end

  def form_builder(form, _soemthing, _valid_changeset?) do
    Form.new(form)
    |> Form.line(&Form.text_field(&1, :relationship, "Relationship to place", span: 4))
    |> Form.line(&Form.text_field(&1, :occurred_on, "Date visited", span: 4))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  def handle_event("save", params, socket) do
    attrs = AddVisitForm.visit_attrs(socket.assigns.case_investigation, socket.assigns.place_address.place, params)

    Cases.create_visit({
      attrs,
      %AuditLog.Meta{
        author_id: socket.assigns.current_user.id,
        reason_action: AuditLog.Revision.add_visit_action(),
        reason_event: AuditLog.Revision.add_visit_event()
      }
    })

    socket
    |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.case_investigation.person)}#case-investigations")
    |> noreply()
  end
end
