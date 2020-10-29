defmodule EpicenterWeb.CaseInvestigationStartLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Format
  alias EpicenterWeb.Form

  defmodule StartForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :person_interviewed, :string
    end

    @required_attrs ~w{person_interviewed}a

    def changeset(%Person{} = person),
      do: person |> case_investigation_start_form_attrs() |> changeset()

    def changeset(attrs),
      do: %StartForm{} |> cast(attrs, @required_attrs) |> validate_required(@required_attrs)

    def case_investigation_start_form_attrs(%Person{} = person),
      do: %{person_interviewed: Format.person(person)}
  end

  def mount(%{"id" => person_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    person = person_id |> Cases.get_person() |> Cases.preload_demographics()

    socket
    |> assign_page_title("Start Case Investigation")
    |> assign_form_changeset(StartForm.changeset(person))
    |> assign(person: person)
    |> ok()
  end

  def handle_event("save", %{}, socket),
    do: noreply(socket)

  def people_interviewed(person),
    do: [Format.person(person)]

  def start_form_builder(form, person) do
    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :person_interviewed, "Person interviewed", people_interviewed(person), other: "Proxy"))
    |> Form.safe()
  end

  # # #

  defp assign_form_changeset(socket, form_changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: form_changeset, form_error: form_error)
end
