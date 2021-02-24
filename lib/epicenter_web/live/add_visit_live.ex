defmodule EpicenterWeb.AddVisitLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.Format, only: [address: 1]

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_form_changeset: 2, assign_page_title: 2, authenticate_user: 2, ok: 1, noreply: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.AddVisitForm

  def mount(params, session, socket) do
    socket = socket |> authenticate_user(session)

    case_investigation =
      Cases.get_case_investigation(params["case_investigation_id"], socket.assigns.current_user)
      |> Cases.preload_person()

    place = Cases.get_place(params["place"])

    place_address =
      if Euclid.Exists.present?(params["place_address"]),
        do: Cases.get_place_address(params["place_address"]) |> Cases.preload_place(),
        else: nil

    socket
    |> assign_defaults()
    |> assign_page_title("Add place visited")
    |> assign(:place, place)
    |> assign(:place_address, place_address)
    |> assign(:place_address_tid, if(place_address, do: place_address.tid, else: nil))
    |> assign(:case_investigation, case_investigation)
    |> assign(:case_investigation_tid, case_investigation.tid)
    |> assign_form_changeset(AddVisitForm.changeset(%AddVisitForm{}, %{}))
    |> ok()
  end

  def form_builder(form, _soemthing, _valid_changeset?) do
    Form.new(form)
    |> Form.line(&Form.text_field(&1, :relationship, "Relationship to place", span: 4))
    |> Form.line(&Form.date_field(&1, :occurred_on, "Date visited", span: 4))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  def handle_event("save", params, socket) do
    with {:form, %Ecto.Changeset{} = form_changeset} <-
           {:form, AddVisitForm.changeset(socket.assigns.form_changeset, params["add_visit_form"])},
         {:data, {:ok, data}} <-
           {:data, AddVisitForm.visit_attrs(form_changeset)},
         data = data |> Map.put(:case_investigation_id, socket.assigns.case_investigation.id),
         data = data |> Map.put(:place_id, socket.assigns.place.id),
         {:save, {:ok, _visit}} <- {:save, Cases.create_visit({data, audit_meta_create_visit(socket)})} do
      socket
      |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.case_investigation.person)}#case-investigations")
      |> noreply()
    else
      {:data, {:error, %Ecto.Changeset{} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()
    end
  end

  defp audit_meta_create_visit(socket) do
    %AuditLog.Meta{
      author_id: socket.assigns.current_user.id,
      reason_action: AuditLog.Revision.add_visit_action(),
      reason_event: AuditLog.Revision.add_visit_event()
    }
  end
end
