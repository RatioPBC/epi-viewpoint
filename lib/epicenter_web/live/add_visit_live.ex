defmodule EpicenterWeb.AddVisitLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.Format, only: [address: 1]

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, ok: 1]

  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.AddVisitForm

  def mount(params, session, socket) do
    socket = socket |> authenticate_user(session)
    case_investigation = Cases.get_case_investigation(params["case_investigation_id"], socket.assigns.current_user)

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
    |> Form.safe()
  end
end
