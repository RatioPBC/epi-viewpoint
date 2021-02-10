defmodule Epicenter.Cases.CaseInvestigation do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.EctoRedactionJasonEncoder
  import Epicenter.Gettext

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.InvestigationNote
  alias Epicenter.ContactInvestigations.ContactInvestigation
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
    isolation_monitoring_ends_on
    isolation_monitoring_starts_on
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
    field :isolation_monitoring_ends_on, :date
    field :isolation_monitoring_starts_on, :date
    field :isolation_monitoring_status, :string, read_after_writes: true
    field :isolation_order_sent_on, :date
    field :name, :string
    field :seq, :integer, read_after_writes: true
    field :symptom_onset_on, :date
    field :symptoms, {:array, :string}
    field :tid, :string

    timestamps(type: :utc_datetime)

    belongs_to :initiating_lab_result, LabResult
    belongs_to :person, Person

    has_many :contact_investigations, ContactInvestigation, foreign_key: :exposing_case_id, where: [deleted_at: nil]
    has_many :notes, InvestigationNote, foreign_key: :case_investigation_id, where: [deleted_at: nil]
  end

  derive_jason_encoder(except: [:seq])

  def changeset(case_investigation, attrs) do
    case_investigation
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> cast_assoc(:notes, with: &InvestigationNote.changeset/2)
    |> validate_required(@required_attrs)
  end

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

    def list(filter)

    def list(:pending_interview) do
      from case_investigation in CaseInvestigation,
        join: person in assoc(case_investigation, :person),
        left_join: assignee in assoc(person, :assigned_to),
        join: lab_result in assoc(case_investigation, :initiating_lab_result),
        where: is_nil(person.archived_at) and case_investigation.interview_status == "pending",
        order_by: [asc_nulls_first: assignee.name, desc: lab_result.sampled_on, asc: case_investigation.seq]
    end

    def list(:ongoing_interview) do
      from case_investigation in CaseInvestigation,
        join: person in assoc(case_investigation, :person),
        left_join: assignee in assoc(person, :assigned_to),
        join: lab_result in assoc(case_investigation, :initiating_lab_result),
        where: is_nil(person.archived_at) and case_investigation.interview_status == "started",
        order_by: [asc_nulls_first: assignee.name, desc: lab_result.sampled_on, asc: case_investigation.seq]
    end

    def list(:isolation_monitoring) do
      from case_investigation in CaseInvestigation,
        join: person in assoc(case_investigation, :person),
        where:
          is_nil(person.archived_at) and
            case_investigation.interview_status == "completed" and
            case_investigation.isolation_monitoring_status in ["pending", "ongoing"],
        order_by: [
          desc: case_investigation.isolation_monitoring_status,
          asc: case_investigation.isolation_monitoring_ends_on,
          desc: case_investigation.interview_completed_at,
          desc: person.seq
        ]
    end

    def list(:all) do
      from case_investigation in CaseInvestigation,
        join: person in assoc(case_investigation, :person),
        left_join: assignee in assoc(person, :assigned_to),
        join: lab_result in assoc(case_investigation, :initiating_lab_result),
        where: is_nil(person.archived_at),
        order_by: [asc_nulls_first: assignee.name, asc: lab_result.sampled_on, asc: case_investigation.seq]
    end

    def assigned_to_user(query, user_id) do
      query
      |> where([case_investigation, person, assignee], assignee.id == ^user_id)
    end
  end
end
