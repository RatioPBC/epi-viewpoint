defmodule Epicenter.Cases.Exposure do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.PhiValidation, only: [validate_phi: 2]
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Person

  @required_attrs ~w{relationship_to_case most_recent_date_together exposing_case_id}a
  @optional_attrs ~w(household_member under_18 tid guardian_phone guardian_name)a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "exposures" do
    field :guardian_name, :string
    field :guardian_phone, :string
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
    |> validate_guardian_fields()
    |> strip_non_digits_from_guardian_phone()
    |> validate_phi(:exposure)
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
end
