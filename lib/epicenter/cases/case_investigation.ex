defmodule Epicenter.Cases.CaseInvestigation do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.EctoRedactionJasonEncoder

  alias Epicenter.Cases.CaseInvestigation
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
    field :isolation_monitoring_end_date, :date
    field :isolation_monitoring_start_date, :date
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
  end

  derive_jason_encoder(except: [:seq])

  def changeset(case_investigation, attrs) do
    case_investigation
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def isolation_monitoring_status(%{isolation_monitoring_start_date: date}) when not is_nil(date), do: :ongoing
  def isolation_monitoring_status(_), do: :pending

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
