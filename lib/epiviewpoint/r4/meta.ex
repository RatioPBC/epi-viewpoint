defmodule Epiviewpoint.R4.Meta do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :last_updated,
    :profile,
    :source,
    :version_id
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:last_updated, :utc_datetime_usec)
    field(:source, :string)
    field(:version_id, :binary_id)

    field(:profile, {:array, :string})

    # Embed Many
    embeds_many(:extension, Epiviewpoint.R4.Extension)
    embeds_many(:security, Epiviewpoint.R4.Coding)
    embeds_many(:tag, Epiviewpoint.R4.Coding)
  end

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:extension)
    |> cast_embed(:security)
    |> cast_embed(:tag)
    |> validate_required(@required_fields)
  end
end