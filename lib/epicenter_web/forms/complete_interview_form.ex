defmodule EpicenterWeb.Forms.CompleteInterviewForm do
  use Ecto.Schema

  import Ecto.Changeset
  import EpicenterWeb.Views.DateExtraction, only: [convert_time: 3, extract_and_validate_date: 4]

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Format
  alias EpicenterWeb.Forms.CompleteInterviewForm

  @primary_key false
  embedded_schema do
    field :date_completed, :string
    field :time_completed, :string
    field :time_completed_am_pm, :string
  end

  @required_attrs ~w{date_completed time_completed time_completed_am_pm}a

  def changeset(%CaseInvestigation{} = case_investigation),
    do: case_investigation |> case_investigation_complete_investigation_form_attrs() |> changeset()

  def changeset(attrs) do
    %CompleteInterviewForm{}
    |> CompleteInterviewForm.cast(attrs)
    |> validate_required(@required_attrs)
    |> extract_and_validate_date(:date_completed, :time_completed, :time_completed_am_pm)
  end

  def cast(data, attrs), do: cast(data, attrs, @required_attrs)

  def case_investigation_complete_investigation_form_attrs(%CaseInvestigation{} = case_investigation) do
    %{completed_interview_at: completed_interview_at} = case_investigation

    if completed_interview_at == nil do
      Timex.now(EpicenterWeb.PresentationConstants.presented_time_zone())
      |> form_attrs_from_date_time()
    else
      completed_interview_at
      |> Timex.Timezone.convert(EpicenterWeb.PresentationConstants.presented_time_zone())
      |> form_attrs_from_date_time()
    end
  end

  def case_investigation_attrs(%Ecto.Changeset{} = changeset) do
    with {:ok, complete_interview_form} <- apply_action(changeset, :create) do
      {:ok, completed_interview_at} = convert_time_completed_and_date_completed(complete_interview_form)
      {:ok, %{completed_interview_at: completed_interview_at}}
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
    %{
      date_completed: Format.date(date_time |> DateTime.to_date()),
      time_completed: Format.time(date_time |> DateTime.to_time()),
      time_completed_am_pm: if(date_time.hour >= 12, do: "PM", else: "AM")
    }
  end
end
