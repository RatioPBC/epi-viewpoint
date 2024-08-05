defmodule EpicenterWeb.Forms.CompleteInterviewForm do
  use Ecto.Schema

  import Ecto.Changeset
  import EpicenterWeb.Views.DateExtraction, only: [convert_time: 3, extract_and_validate_date: 4]

  alias EpicenterWeb.Format

  @primary_key false
  embedded_schema do
    field(:date_completed, :string)
    field(:time_completed, :string)
    field(:time_completed_am_pm, :string)
  end

  @required_attrs ~w{date_completed time_completed time_completed_am_pm}a

  def changeset(%{interview_completed_at: _interview_completed_at} = investigation, attrs) do
    investigation
    |> investigation_complete_interview_form_attrs()
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> extract_and_validate_date(:date_completed, :time_completed, :time_completed_am_pm)
  end

  defp investigation_complete_interview_form_attrs(%{
         interview_completed_at: interview_completed_at
       }) do
    if interview_completed_at == nil do
      Timex.now(EpicenterWeb.PresentationConstants.presented_time_zone())
      |> form_attrs_from_date_time()
    else
      interview_completed_at
      |> Timex.Timezone.convert(EpicenterWeb.PresentationConstants.presented_time_zone())
      |> form_attrs_from_date_time()
    end
  end

  def investigation_attrs(%Ecto.Changeset{} = changeset) do
    with {:ok, complete_interview_form} <- apply_action(changeset, :create) do
      {:ok, interview_completed_at} = convert_time_completed_and_date_completed(complete_interview_form)

      {:ok, %{interview_completed_at: interview_completed_at}}
    else
      other -> other
    end
  end

  defp convert_time_completed_and_date_completed(attrs) do
    date = attrs |> Map.get(:date_completed)
    time = attrs |> Map.get(:time_completed)
    am_pm = attrs |> Map.get(:time_completed_am_pm)
    convert_time(date, time, am_pm)
  end

  defp form_attrs_from_date_time(date_time) do
    %__MODULE__{
      date_completed: Format.date(date_time |> DateTime.to_date()),
      time_completed: Format.time(date_time |> DateTime.to_time()),
      time_completed_am_pm: if(date_time.hour >= 12, do: "PM", else: "AM")
    }
  end
end
