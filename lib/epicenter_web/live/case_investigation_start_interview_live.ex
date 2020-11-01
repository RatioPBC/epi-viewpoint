defmodule EpicenterWeb.CaseInvestigationStartInterviewLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.AuditLog
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

    @required_attrs ~w{date_started person_interviewed time_started time_started_am_pm}a

    def changeset(%Person{} = person),
      do: person |> case_investigation_start_interview_form_attrs() |> changeset()

    def changeset(attrs),
      do: %StartInterviewForm{} |> cast(attrs, @required_attrs) |> validate_required(@required_attrs)

    def case_investigation_start_interview_form_attrs(%Person{} = person) do
      local_now = Timex.now(EpicenterWeb.CaseInvestigationStartInterviewLive.time_zone_name())

      %{
        person_interviewed: Format.person(person),
        date_started: Format.date(local_now |> DateTime.to_date()),
        time_started: Format.time(local_now |> DateTime.to_time()),
        time_started_am_pm: if(local_now.hour >= 12, do: "PM", else: "AM")
      }
    end

    def case_investigation_attrs(%Ecto.Changeset{} = changeset) do
      case apply_action(changeset, :create) do
        {:ok, case_investigation_start_form} -> {:ok, case_investigation_attrs(case_investigation_start_form)}
        other -> other
      end
    end

    def case_investigation_attrs(%StartInterviewForm{} = start_interview_form),
      do: start_interview_form |> Map.from_struct() |> convert_name()

    def convert_name(attrs) do
      attrs |> Map.put(:person_interviewed, Map.get(attrs, :person_interviewed))
    end
  end

  def mount(%{"case_investigation_id" => case_investigation_id, "id" => person_id}, session, socket) do
    case_investigation = case_investigation_id |> Cases.get_case_investigation()
    person = person_id |> Cases.get_person() |> Cases.preload_demographics()
    socket = socket |> authenticate_user(session)

    socket
    |> assign_page_title("Start Case Investigation")
    |> assign_form_changeset(StartInterviewForm.changeset(person))
    |> assign(case_investigation: case_investigation)
    |> assign(person: person)
    |> ok()
  end

  def handle_event("save", %{"start_interview_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- StartInterviewForm.changeset(params),
         {:form, {:ok, cast_investigation_attrs}} <- {:form, StartInterviewForm.case_investigation_attrs(form_changeset)},
         {:case_investigation, {:ok, _case_investigation}} <- {:case_investigation, update_case_investigation(socket, cast_investigation_attrs)} do
      socket |> redirect_to_profile_page() |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:case_investigation, {:error, _}} ->
        socket |> assign_form_changeset(StartInterviewForm.changeset(params), "An unexpected error occurred") |> noreply()
    end
  end

  defp update_case_investigation(socket, params) do
    Cases.update_case_investigation(
      socket.assigns.case_investigation,
      {params,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.update_case_investigation_action(),
         reason_event: AuditLog.Revision.discontinue_pending_case_interview_event()
       }}
    )
  end

  def people_interviewed(person),
    do: [Format.person(person)]

  def time_started_am_pm_options(),
    do: ["AM", "PM"]

  def time_zone_name(), do: "America/New_York"

  def start_interview_form_builder(form, person) do
    timezone = Timex.timezone(time_zone_name(), Timex.now())

    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :person_interviewed, "Person interviewed", people_interviewed(person), other: "Proxy"))
    |> Form.line(&Form.date_field(&1, :date_started, "Date started"))
    |> Form.line(fn line ->
      line
      |> Form.text_field(:time_started, "Time interviewed")
      |> Form.select(:time_started_am_pm, "", time_started_am_pm_options(), span: 1)
      |> Form.content_div(timezone.abbreviation)
    end)
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  # # #

  defp assign_form_changeset(socket, form_changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: form_changeset, form_error: form_error)

  defp redirect_to_profile_page(socket),
    do: socket |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person)}#case-investigations")
end
