defmodule Epicenter.Cases.Exposure do
  use Ecto.Schema

  import Ecto.Changeset
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Person

  @required_attrs ~w{relationship_to_case most_recent_date_together exposing_case_id}a
  @optional_attrs ~w(household_member under_18 tid)a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "exposures" do
    field :seq, :integer
    field :tid, :string
    field :relationship_to_case, :string
    field :household_member, :boolean
    field :under_18, :boolean
    field :most_recent_date_together, :date

    timestamps(type: :utc_datetime)

    belongs_to :exposed_person, Person
    belongs_to :exposing_case, CaseInvestigation
  end

  def changeset(exposure, attrs) do
    exposure
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> cast_assoc(:exposed_person, with: &Person.changeset/2)
  end
end
