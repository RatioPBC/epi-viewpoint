defmodule Epiviewpoint.R4.CodeableConcept do
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

    # Embed Many
    embeds_many(:coding, Epiviewpoint.R4.Coding)
    embeds_many(:extension, Epiviewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:coding)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end