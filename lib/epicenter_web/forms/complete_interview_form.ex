defmodule EpicenterWeb.Forms.CompleteInterviewForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Format
  alias EpicenterWeb.Forms.CompleteInterviewForm

  @primary_key false
  embedded_schema do
    field :time_completed, :string
    field :time_completed_am_pm, :string
  end

  @required_attrs ~w{time_completed time_completed_am_pm}a

  def changeset(%CaseInvestigation{} = case_investigation),
    do: case_investigation |> case_investigation_complete_investigation_form_attrs() |> changeset()

  def changeset(attrs), do: %CompleteInterviewForm{} |> cast(attrs, @required_attrs)

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

  defp form_attrs_from_date_time(date_time) do
    %{
      date_completed: Format.date(date_time |> DateTime.to_date()),
      time_completed: Format.time(date_time |> DateTime.to_time()),
      time_completed_am_pm: if(date_time.hour >= 12, do: "PM", else: "AM")
    }
  end
end
