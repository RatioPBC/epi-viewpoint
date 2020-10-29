defmodule EpicenterWeb.CaseInvestigationStartInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Format
  alias EpicenterWeb.Form

  defmodule StartInterviewForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :person_interviewed, :string
      field :date_started, :string
      field :time_started, :string
      field :time_started_am_pm, :string
    end

    @required_attrs ~w{person_interviewed}a

    def changeset(%Person{} = person),
      do: person |> case_investigation_start_interview_form_attrs() |> changeset()

    def changeset(attrs),
      do: %StartInterviewForm{} |> cast(attrs, @required_attrs) |> validate_required(@required_attrs)

    def case_investigation_start_interview_form_attrs(%Person{} = person) do
      %{
        person_interviewed: Format.person(person),
        date_started: Format.date(Date.utc_today()),
        time_started: Format.time(Time.utc_now()),
        time_started_am_pm: if(Time.utc_now().hour >= 12, do: "PM", else: "AM")
      }
    end
  end

  def mount(%{"id" => person_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    person = person_id |> Cases.get_person() |> Cases.preload_demographics()

    socket
    |> assign_page_title("Start Case Investigation")
    |> assign_form_changeset(StartInterviewForm.changeset(person))
    |> assign(person: person)
    |> ok()
  end

  def handle_event("save", %{}, socket),
    do: noreply(socket)

  def people_interviewed(person),
    do: [Format.person(person)]

  def time_started_am_pm_options(),
    do: ["AM", "PM"]

  def start_interview_form_builder(form, person) do
    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :person_interviewed, "Person interviewed", people_interviewed(person), other: "Proxy"))
    |> Form.line(&Form.date_field(&1, :date_started, "Date started"))
    |> Form.line(fn line ->
      line
      |> Form.text_field(:time_started, "Time interviewed")
      |> Form.select(:time_started_am_pm, "", time_started_am_pm_options(), 1)
    end)
    |> Form.safe()
  end

  # # #

  defp assign_form_changeset(socket, form_changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: form_changeset, form_error: form_error)
end
