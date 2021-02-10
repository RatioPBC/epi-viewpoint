defmodule Epicenter.ContactInvestigations.ContactInvestigation do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.Gettext
  import Epicenter.PhiValidation, only: [validate_phi: 2]

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.InvestigationNote
  alias Epicenter.Cases.Person

  @required_attrs ~w{exposing_case_id most_recent_date_together relationship_to_case}a
  @optional_attrs ~w{
    clinical_status
    deleted_at
    exposed_on
    exposed_person_id
    guardian_name
    guardian_phone
    household_member
    interview_completed_at
    interview_discontinue_reason
    interview_discontinued_at
    interview_proxy_name
    interview_started_at
    quarantine_conclusion_reason
    quarantine_concluded_at
    quarantine_monitoring_ends_on
    quarantine_monitoring_starts_on
    symptoms
    tid
    under_18
  }a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contact_investigations" do
    field :clinical_status, :string
    field :deleted_at, :utc_datetime
    field :exposed_on, :date
    field :guardian_name, :string
    field :guardian_phone, :string
    field :household_member, :boolean
    field :interview_completed_at, :utc_datetime
    field :interview_discontinue_reason, :string
    field :interview_discontinued_at, :utc_datetime
    field :interview_proxy_name, :string
    field :interview_started_at, :utc_datetime
    field :interview_status, :string, read_after_writes: true
    field :most_recent_date_together, :date
    field :quarantine_conclusion_reason, :string
    field :quarantine_concluded_at, :utc_datetime
    field :quarantine_monitoring_ends_on, :date
    field :quarantine_monitoring_starts_on, :date
    field :quarantine_monitoring_status, :string, read_after_writes: true
    field :relationship_to_case, :string
    field :seq, :integer, read_after_writes: true
    field :symptoms, {:array, :string}
    field :tid, :string
    field :under_18, :boolean

    timestamps(type: :utc_datetime)

    belongs_to :exposed_person, Person
    belongs_to :exposing_case, CaseInvestigation
    has_many :notes, InvestigationNote, foreign_key: :contact_investigation_id, where: [deleted_at: nil]
  end

  def changeset(contact_investigation, attrs) do
    contact_investigation
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> cast_assoc(:exposed_person, with: &Person.changeset/2)
    |> validate_guardian_fields()
    |> strip_non_digits_from_guardian_phone()
    |> validate_phi(:contact_investigation)
  end

  def changeset_for_merge(changeset_or_investigation, canonical_person_id) do
    changeset(changeset_or_investigation, %{exposed_person_id: canonical_person_id})
  end

  def validate_guardian_fields(changeset) do
    case fetch_field(changeset, :under_18) do
      {_, true} -> validate_required(changeset, [:guardian_name])
      _ -> changeset
    end
  end

  defp strip_non_digits_from_guardian_phone(%Ecto.Changeset{} = changeset) do
    case Ecto.Changeset.fetch_field(changeset, :guardian_phone) do
      {_, number} when not is_nil(number) -> Ecto.Changeset.put_change(changeset, :guardian_phone, strip_non_digits_from_number(number))
      _ -> changeset
    end
  end

  defp strip_non_digits_from_number(number) when is_binary(number) do
    number
    |> String.graphemes()
    |> Enum.filter(fn element -> element =~ ~r{\d} end)
    |> Enum.join()
  end

  def text_field_values(field_name) do
    %{
      quarantine_conclusion_reason: [
        gettext_noop("successfully_completed_quarantine"),
        gettext_noop("unable_to_quarantine"),
        gettext_noop("refused_to_cooperate"),
        gettext_noop("lost_to_follow_up"),
        gettext_noop("transferred"),
        gettext_noop("deceased")
      ]
    }[field_name]
  end

  defmodule Query do
    import Ecto.Query

    alias Epicenter.ContactInvestigations.ContactInvestigation

    def display_order() do
      from contact_investigation in ContactInvestigation,
        order_by: [asc: contact_investigation.seq]
    end
  end
end
