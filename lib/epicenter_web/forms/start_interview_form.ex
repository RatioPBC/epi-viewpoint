defmodule EpicenterWeb.Forms.StartInterviewForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Format
  alias EpicenterWeb.Forms.StartInterviewForm
  alias EpicenterWeb.PresentationConstants

  @primary_key false
  embedded_schema do
    field :person_interviewed, :string
    field :date_started, :string
    field :time_started, :string
    field :time_started_am_pm, :string
  end

  @required_attrs ~w{date_started person_interviewed time_started time_started_am_pm}a
  @interview_non_proxy_sentinel_value "~~self~~"

  def changeset(%CaseInvestigation{} = case_investigation),
    do: case_investigation |> case_investigation_start_interview_form_attrs() |> changeset()

  def changeset(attrs),
    do: %StartInterviewForm{} |> cast(attrs, @required_attrs) |> validate_required(@required_attrs) |> validate_interviewed_at()

  def case_investigation_start_interview_form_attrs(%CaseInvestigation{} = case_investigation) do
    local_now = Timex.now(EpicenterWeb.PresentationConstants.presented_time_zone())

    time =
      with(
        time when not is_nil(time) <- case_investigation.started_at,
        do: Timex.Timezone.convert(time, EpicenterWeb.PresentationConstants.presented_time_zone())
      ) || local_now

    %{
      person_interviewed: person_interviewed(case_investigation),
      date_started: Format.date(time |> DateTime.to_date()),
      time_started: Format.time(time |> DateTime.to_time()),
      time_started_am_pm: if(time.hour >= 12, do: "PM", else: "AM")
    }
  end

  def case_investigation_attrs(%Ecto.Changeset{} = changeset) do
    case apply_action(changeset, :create) do
      {:ok, case_investigation_start_form} -> {:ok, case_investigation_attrs(case_investigation_start_form)}
      other -> other
    end
  end

  def case_investigation_attrs(%StartInterviewForm{} = start_interview_form) do
    interview_proxy_name = convert_name(start_interview_form)
    {:ok, started_at} = convert_time_started_and_date_started(start_interview_form)
    %{interview_proxy_name: interview_proxy_name, started_at: started_at}
  end

  defp convert_name(%{person_interviewed: @interview_non_proxy_sentinel_value} = _attrs),
    do: nil

  defp convert_name(attrs),
    do: Map.get(attrs, :person_interviewed)

  defp convert_time(datestring, timestring, ampmstring) do
    with {:ok, datetime} <- Timex.parse("#{datestring} #{timestring} #{ampmstring}", "{0M}/{0D}/{YYYY} {h12}:{m} {AM}"),
         %Timex.TimezoneInfo{} = timezone <- Timex.timezone(PresentationConstants.presented_time_zone(), datetime),
         %DateTime{} = time <- Timex.to_datetime(datetime, timezone) do
      {:ok, time}
    end
  end

  defp convert_time_started_and_date_started(attrs) do
    date = attrs |> Map.get(:date_started)
    time = attrs |> Map.get(:time_started)
    am_pm = attrs |> Map.get(:time_started_am_pm)
    convert_time(date, time, am_pm)
  end

  def interview_non_proxy_sentinel_value(),
    do: @interview_non_proxy_sentinel_value

  defp person_interviewed(%CaseInvestigation{interview_proxy_name: nil}),
    do: interview_non_proxy_sentinel_value()

  defp person_interviewed(%CaseInvestigation{interview_proxy_name: interview_proxy_name}),
    do: interview_proxy_name

  defp validate_interviewed_at(changeset) do
    with {_, date} <- fetch_field(changeset, :date_started),
         {_, time} <- fetch_field(changeset, :time_started),
         {_, am_pm} <- fetch_field(changeset, :time_started_am_pm),
         {:date_started, {:ok, _}} <- {:date_started, convert_time(date, "12:00", "PM")},
         {:time_started, {:ok, _}} <- {:time_started, convert_time("01/01/2000", time, "PM")},
         {:together, {:ok, _}} <- {:together, convert_time(date, time, am_pm)} do
      changeset
    else
      {:together, _} -> changeset |> add_error(:time_started, "is invalid")
      {field, _} -> changeset |> add_error(field, "is invalid")
      _ -> changeset
    end
  end
end
