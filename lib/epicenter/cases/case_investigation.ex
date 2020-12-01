defmodule Epicenter.Cases.CaseInvestigation do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.EctoRedactionJasonEncoder
  import Epicenter.Gettext

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.CaseInvestigationNote
  alias Epicenter.Cases.Exposure
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person

  @required_attrs ~w{initiating_lab_result_id person_id}a
  @optional_attrs ~w{
    clinical_status
    interview_completed_at
    interview_discontinue_reason
    interview_discontinued_at
    interview_proxy_name
    interview_started_at
    isolation_clearance_order_sent_on
    isolation_concluded_at
    isolation_conclusion_reason
    isolation_monitoring_ended_on
    isolation_monitoring_started_on
    isolation_order_sent_on
    name
    symptom_onset_on
    symptoms
    tid
  }a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "case_investigations" do
    field :clinical_status, :string
    field :interview_completed_at, :utc_datetime
    field :interview_discontinue_reason, :string
    field :interview_discontinued_at, :utc_datetime
    field :interview_proxy_name, :string
    field :interview_started_at, :utc_datetime
    field :interview_status, :string, read_after_writes: true
    field :isolation_clearance_order_sent_on, :date
    field :isolation_concluded_at, :utc_datetime
    field :isolation_conclusion_reason, :string
    field :isolation_monitoring_ended_on, :date
    field :isolation_monitoring_started_on, :date
    field :isolation_order_sent_on, :date
    field :name, :string
    field :seq, :integer
    field :symptom_onset_on, :date
    field :symptoms, {:array, :string}
    field :tid, :string

    timestamps(type: :utc_datetime)

    belongs_to :initiating_lab_result, LabResult
    belongs_to :person, Person

    has_many :exposures, Exposure, foreign_key: :exposing_case_id, where: [deleted_at: nil]
    has_many :notes, CaseInvestigationNote, foreign_key: :case_investigation_id, where: [deleted_at: nil]
  end

  derive_jason_encoder(except: [:seq])

  def changeset(case_investigation, attrs) do
    case_investigation
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> cast_assoc(:notes, with: &CaseInvestigationNote.changeset/2)
    |> validate_required(@required_attrs)
  end

  def isolation_monitoring_status(%{isolation_concluded_at: timestamp}) when not is_nil(timestamp), do: :concluded
  def isolation_monitoring_status(%{isolation_monitoring_started_on: date}) when not is_nil(date), do: :ongoing
  def isolation_monitoring_status(_), do: :pending

  def text_field_values(field_name) do
    %{
      clinical_status: [
        gettext_noop("unknown"),
        gettext_noop("symptomatic"),
        gettext_noop("asymptomatic")
      ],
      isolation_conclusion_reason: [
        gettext_noop("successfully_completed"),
        gettext_noop("unable_to_isolate"),
        gettext_noop("refused_to_cooperate"),
        gettext_noop("lost_to_follow_up"),
        gettext_noop("transferred"),
        gettext_noop("deceased")
      ]
    }[field_name]
  end

  defmodule Query do
    import Ecto.Query

    def display_order() do
      from case_investigation in CaseInvestigation,
        order_by: [asc: case_investigation.seq]
    end
  end
end
