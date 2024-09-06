defmodule Epiviewpoint.R4.ContactDetail do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :name
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:name, :string)

    # Embed Many
    embeds_many(:extension, Epiviewpoint.R4.Extension)
    embeds_many(:telecom, Epiviewpoint.R4.ContactPoint)
  end

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:extension)
    |> cast_embed(:telecom)
    |> validate_required(@required_fields)
  end
end