defmodule EpicenterWeb.Forms.StartInterviewForm do
  use Ecto.Schema

  import Ecto.Changeset
  import EpicenterWeb.Views.DateExtraction, only: [convert_time: 3, extract_and_validate_date: 4]

  alias EpicenterWeb.Format
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.StartInterviewForm
  alias EpicenterWeb.PresentationConstants

  @primary_key false
  embedded_schema do
    field(:person_interviewed, :string)
    field(:date_started, :string)
    field(:time_started, :string)
    field(:time_started_am_pm, :string)
  end

  @required_attrs ~w{date_started person_interviewed time_started time_started_am_pm}a
  @interview_non_proxy_sentinel_value "~~self~~"

  def changeset(investigation, attrs) do
    investigation
    |> investigation_start_interview_form_attrs()
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> extract_and_validate_date(:date_started, :time_started, :time_started_am_pm)
  end

  # Pre-filling the form

  defp investigation_start_interview_form_attrs(%{interview_started_at: interview_started_at} = investigation) do
    time =
      if interview_started_at do
        Timex.Timezone.convert(
          interview_started_at,
          EpicenterWeb.PresentationConstants.presented_time_zone()
        )
      else
        Timex.now(EpicenterWeb.PresentationConstants.presented_time_zone())
      end

    %StartInterviewForm{
      person_interviewed: person_interviewed(investigation),
      date_started: Format.date(time |> DateTime.to_date()),
      time_started: Format.time(time |> DateTime.to_time()),
      time_started_am_pm: if(time.hour >= 12, do: "PM", else: "AM")
    }
  end

  defp person_interviewed(%{interview_proxy_name: nil}),
    do: @interview_non_proxy_sentinel_value

  defp person_interviewed(%{interview_proxy_name: interview_proxy_name}),
    do: interview_proxy_name

  # Extract from form

  def investigation_attrs(%Ecto.Changeset{} = form_changeset) do
    with {:ok, case_investigation_start_form} <- apply_action(form_changeset, :create) do
      interview_proxy_name = convert_name(case_investigation_start_form)

      {:ok, interview_started_at} = convert_time_started_and_date_started(case_investigation_start_form)

      {:ok, %{interview_proxy_name: interview_proxy_name, interview_started_at: interview_started_at}}
    else
      other -> other
    end
  end

  defp convert_name(%{person_interviewed: @interview_non_proxy_sentinel_value} = _attrs),
    do: nil

  defp convert_name(attrs),
    do: Map.get(attrs, :person_interviewed)

  defp convert_time_started_and_date_started(attrs) do
    date = attrs |> Map.get(:date_started)
    time = attrs |> Map.get(:time_started)
    am_pm = attrs |> Map.get(:time_started_am_pm)
    convert_time(date, time, am_pm)
  end

  # Rendering the form

  def start_interview_form_builder(form, person) do
    timezone = Timex.timezone(PresentationConstants.presented_time_zone(), Timex.now())

    Form.new(form)
    |> Form.line(
      &Form.radio_button_list(
        &1,
        :person_interviewed,
        "Person interviewed",
        people_interviewed(person),
        other: "Proxy"
      )
    )
    |> Form.line(&Form.date_field(&1, :date_started, "Date started"))
    |> Form.line(fn line ->
      line
      |> Form.text_field(:time_started, "Time interviewed")
      |> Form.select(:time_started_am_pm, "", PresentationConstants.am_pm_options(), span: 1)
      |> Form.content_div(timezone.abbreviation, row: 3)
    end)
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end

  defp people_interviewed(person),
    do: [{Format.person(person), @interview_non_proxy_sentinel_value}]
end
