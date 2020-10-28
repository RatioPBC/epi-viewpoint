defmodule EpicenterWeb.CaseInvestigationStartLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.Cases
  alias EpicenterWeb.Form

  def mount(%{"id" => person_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    person = Cases.get_person(person_id) |> Cases.preload_case_investigations()
    changeset = person.case_investigations |> List.first() |> Cases.change_case_investigation(%{})

    socket
    |> assign_page_title("Start Case Investigation")
    |> assign(person: person)
    |> assign(changeset: changeset)
    |> ok()
  end

  def handle_event("save", %{}, socket),
    do: noreply(socket)

  def people_interviewed() do
    ["Jacob Wunderbar"]
  end

  def start_form_builder(changeset) do
    Form.new(changeset)
    |> Form.line(fn line -> line |> Form.radio_button_list(:person_interview, "Person interviewed", people_interviewed(), other: "Proxy") end)
    |> Form.safe()
  end
end
