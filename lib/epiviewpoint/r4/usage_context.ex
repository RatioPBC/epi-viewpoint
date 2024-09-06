defmodule EpiViewpoint.R4.UsageContext do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id
  ]
  @required_fields []

  embedded_schema do
    # Embed One
    embeds_one(:code, EpiViewpoint.R4.Coding)
    embeds_one(:value_codeable_concept, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:value_quantity, EpiViewpoint.R4.Quantity)
    embeds_one(:value_range, EpiViewpoint.R4.Range)
    embeds_one(:value_reference, EpiViewpoint.R4.Reference)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices("value") do
    [:value_codeable_concept, :value_quantity, :value_range, :value_reference]
  end

  def choices("valueCodeableConcept"), do: :error

  def choices("valueQuantity"), do: :error

  def choices("valueRange"), do: :error

  def choices("valueReference"), do: :error

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:code)
    |> cast_embed(:value_codeable_concept)
    |> cast_embed(:value_quantity)
    |> cast_embed(:value_range)
    |> cast_embed(:value_reference)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
