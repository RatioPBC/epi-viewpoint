defmodule Epicenter.Cases.CaseInvestigation do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.EctoRedactionJasonEncoder

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person

  @required_attrs ~w{initiated_by_id person_id}a
  @optional_attrs ~w{name tid}a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "case_investigations" do
    field :name, :string
    field :seq, :integer
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

  defmodule Query do
    import Ecto.Query

    def display_order() do
      from case_investigation in CaseInvestigation,
        order_by: [asc: case_investigation.seq]
    end
  end
end
