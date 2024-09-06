defmodule Epiviewpoint.R4.Organization.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id
  ]
  @required_fields []

  embedded_schema do
    # Embed One
    embeds_one(:address, Epiviewpoint.R4.Address)
    embeds_one(:name, Epiviewpoint.R4.HumanName)
    embeds_one(:purpose, Epiviewpoint.R4.CodeableConcept)

    # Embed Many
    embeds_many(:extension, Epiviewpoint.R4.Extension)
    embeds_many(:modifier_extension, Epiviewpoint.R4.Extension)
    embeds_many(:telecom, Epiviewpoint.R4.ContactPoint)
  end

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:address)
    |> cast_embed(:name)
    |> cast_embed(:purpose)
    |> cast_embed(:extension)
    |> cast_embed(:modifier_extension)
    |> cast_embed(:telecom)
    |> validate_required(@required_fields)
  end
end