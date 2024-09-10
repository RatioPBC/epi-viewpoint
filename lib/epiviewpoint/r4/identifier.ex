defmodule EpiViewpoint.R4.Identifier do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :system,
    :use,
    :value
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:system, :string)
    field(:value, :string)

    # Enum
    field(:use, Ecto.Enum,
      values: [
        :usual,
        :official,
        :temp,
        :secondary,
        :old
      ]
    )

    # Embed One
    embeds_one(:assigner, EpiViewpoint.R4.Reference)
    embeds_one(:period, EpiViewpoint.R4.Period)
    embeds_one(:type, EpiViewpoint.R4.CodeableConcept)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:assigner)
    |> cast_embed(:period)
    |> cast_embed(:type)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
