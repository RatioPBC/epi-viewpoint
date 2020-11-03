defmodule Epicenter.Cases.CaseInvestigation do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.EctoRedactionJasonEncoder

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person

  @required_attrs ~w{initiated_by_id person_id}a
  @optional_attrs ~w{clinical_status discontinue_reason discontinued_at person_interviewed name started_at symptom_onset_date symptoms tid}a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "case_investigations" do
    field :clinical_status, :string
    field :discontinue_reason, :string
    field :discontinued_at, :utc_datetime
    field :person_interviewed, :string
    field :name, :string
    field :seq, :integer
    field :started_at, :utc_datetime
    field :symptom_onset_date, :date
    field :symptoms, {:array, :string}
    field :tid, :string

    timestamps(type: :utc_datetime)

    belongs_to :initiated_by, LabResult
    belongs_to :person, Person
  end

  derive_jason_encoder(except: [:seq])

  def changeset(case_investigation, attrs) do
    case_investigation
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  @spec status(%CaseInvestigation{}) :: :pending | :discontinued
  def status(%{discontinued_at: timestamp}) when not is_nil(timestamp), do: :discontinued
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
