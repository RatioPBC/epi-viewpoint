defmodule Epicenter.Cases.CaseInvestigation do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.EctoRedactionJasonEncoder

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.CaseInvestigationNote
  alias Epicenter.Cases.Exposure
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person

  @required_attrs ~w{initiating_lab_result_id person_id}a
  @optional_attrs ~w{
    clinical_status
    completed_interview_at
    discontinue_reason
    discontinued_at
    interview_proxy_name
    isolation_concluded_at
    isolation_conclusion_reason
    isolation_monitoring_end_date
    isolation_monitoring_start_date
    name
    started_at
    symptom_onset_date
    symptoms
    tid
  }a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "case_investigations" do
    field :clinical_status, :string
    field :completed_interview_at, :utc_datetime
    field :discontinue_reason, :string
    field :discontinued_at, :utc_datetime
    field :interview_proxy_name, :string
    field :isolation_concluded_at, :utc_datetime
    field :isolation_conclusion_reason, :string
    field :isolation_monitoring_end_date, :date
    field :isolation_monitoring_start_date, :date
    field :isolation_clearance_order_sent_date, :date
    field :isolation_order_sent_date, :date
    field :name, :string
    field :seq, :integer
    field :started_at, :utc_datetime
    field :symptom_onset_date, :date
    field :symptoms, {:array, :string}
    field :tid, :string

    timestamps(type: :utc_datetime)

    belongs_to :initiating_lab_result, LabResult
    belongs_to :person, Person

    has_many :exposures, Exposure, foreign_key: :exposing_case_id, where: [deleted_at: nil]
    has_many :notes, CaseInvestigationNote, foreign_key: :case_investigation_id
  end

  derive_jason_encoder(except: [:seq])

  def changeset(case_investigation, attrs) do
    case_investigation
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def isolation_monitoring_status(%{isolation_concluded_at: timestamp}) when not is_nil(timestamp), do: :concluded
  def isolation_monitoring_status(%{isolation_monitoring_start_date: date}) when not is_nil(date), do: :ongoing
  def isolation_monitoring_status(_), do: :pending

  def humanized_values() do
    %{
      isolation_conclusion_reason: [
        {"Successfully completed isolation period", "successfully_completed"},
        {"Person unable to isolate", "unable_to_isolate"},
        {"Refused to cooperate", "refused_to_cooperate"},
        {"Lost to follow up", "lost_to_follow_up"},
        {"Transferred to another jurisdiction", "transferred"},
        {"Deceased", "deceased"}
      ]
    }
  end

  def find_humanized_value(field, value) do
    case Map.get(humanized_values(), field) do
      nil ->
        value

      humanized_values_for_field ->
        default = {value, value}
        {humanized, _val} = Enum.find(humanized_values_for_field, default, fn {_humanized, val} -> val == value end)
        humanized
    end
  end

  @spec status(%CaseInvestigation{}) :: :pending | :started | :discontinued | :completed_interview
  def status(%{discontinued_at: timestamp}) when not is_nil(timestamp), do: :discontinued
  def status(%{completed_interview_at: timestamp}) when not is_nil(timestamp), do: :completed_interview
  def status(%{started_at: timestamp}) when not is_nil(timestamp), do: :started
  def status(_), do: :pending

  defmodule Query do
    import Ecto.Query

    def display_order() do
      from case_investigation in CaseInvestigation,
        order_by: [asc: case_investigation.seq]
    end
  end
end
