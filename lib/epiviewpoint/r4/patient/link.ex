defmodule EpiViewpoint.R4.Patient.Link do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :type
  ]
  @required_fields []

  embedded_schema do
    # Enum
    field(:type, Ecto.Enum,
      values: [
        :replaced_by,
        :replaces,
        :refer,
        :seealso
      ]
    )

    # Embed One
    embeds_one(:other, EpiViewpoint.R4.Reference)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
    embeds_many(:modifier_extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:other)
    |> cast_embed(:extension)
    |> cast_embed(:modifier_extension)
    |> validate_required(@required_fields)
  end
end
