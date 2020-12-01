defmodule EpicenterWeb.Forms.StartInterviewForm do
  use Ecto.Schema

  import Ecto.Changeset
  import EpicenterWeb.Views.DateExtraction, only: [convert_time: 3, extract_and_validate_date: 4]

  alias Epicenter.Cases.CaseInvestigation
  alias EpicenterWeb.Format
  alias EpicenterWeb.Forms.StartInterviewForm

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

  def changeset(attrs) do
    %StartInterviewForm{}
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> extract_and_validate_date(:date_started, :time_started, :time_started_am_pm)
  end

  def case_investigation_start_interview_form_attrs(%CaseInvestigation{} = case_investigation) do
    local_now = Timex.now(EpicenterWeb.PresentationConstants.presented_time_zone())

    time =
      with(
        time when not is_nil(time) <- case_investigation.interview_started_at,
        do: Timex.Timezone.convert(time, EpicenterWeb.PresentationConstants.presented_time_zone())
      ) || local_now

    %{
      person_interviewed: person_interviewed(case_investigation),
      date_started: Format.date(time |> DateTime.to_date()),
      time_started: Format.time(time |> DateTime.to_time()),
      time_started_am_pm: if(time.hour >= 12, do: "PM", else: "AM")
    }
  end

  def case_investigation_attrs(%Ecto.Changeset{} = form_changeset) do
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

  def interview_non_proxy_sentinel_value(),
    do: @interview_non_proxy_sentinel_value

  defp person_interviewed(%CaseInvestigation{interview_proxy_name: nil}),
    do: interview_non_proxy_sentinel_value()

  defp person_interviewed(%CaseInvestigation{interview_proxy_name: interview_proxy_name}),
    do: interview_proxy_name
end
