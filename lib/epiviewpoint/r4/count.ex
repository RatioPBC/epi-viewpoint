defmodule Epiviewpoint.R4.Count do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :code,
    :comparator,
    :id,
    :system,
    :unit,
    :value
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:code, :string)
    field(:system, :string)
    field(:unit, :string)
    field(:value, :decimal)

    # Enum
    field(:comparator, Ecto.Enum,
      values: [
        :<,
        :<=,
        :>=,
        :>
      ]
    )

    # Embed Many
    embeds_many(:extension, Epiviewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end