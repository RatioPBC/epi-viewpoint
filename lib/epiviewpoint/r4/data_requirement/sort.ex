defmodule Epiviewpoint.R4.DataRequirement.Sort do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :direction,
    :id,
    :path
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:path, :string)

    # Enum
    field(:direction, Ecto.Enum,
      values: [
        :ascending,
        :descending
      ]
    )

    # Embed Many
    embeds_many(:extension, Epiviewpoint.R4.Extension)
    embeds_many(:modifier_extension, Epiviewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:extension)
    |> cast_embed(:modifier_extension)
    |> validate_required(@required_fields)
  end
end