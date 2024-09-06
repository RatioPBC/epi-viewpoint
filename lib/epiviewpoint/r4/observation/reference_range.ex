defmodule Epiviewpoint.R4.Observation.ReferenceRange do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :text
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:text, :string)

    # Embed One
    embeds_one(:age, Epiviewpoint.R4.Range)
    embeds_one(:high, Epiviewpoint.R4.Quantity)
    embeds_one(:low, Epiviewpoint.R4.Quantity)
    embeds_one(:type, Epiviewpoint.R4.CodeableConcept)

    # Embed Many
    embeds_many(:applies_to, Epiviewpoint.R4.CodeableConcept)
    embeds_many(:extension, Epiviewpoint.R4.Extension)
    embeds_many(:modifier_extension, Epiviewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:age)
    |> cast_embed(:high)
    |> cast_embed(:low)
    |> cast_embed(:type)
    |> cast_embed(:applies_to)
    |> cast_embed(:extension)
    |> cast_embed(:modifier_extension)
    |> validate_required(@required_fields)
  end
end