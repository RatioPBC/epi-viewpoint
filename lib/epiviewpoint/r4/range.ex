defmodule EpiViewpoint.R4.Range do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id
  ]
  @required_fields []

  embedded_schema do
    # Embed One
    embeds_one(:high, EpiViewpoint.R4.Quantity)
    embeds_one(:low, EpiViewpoint.R4.Quantity)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:high)
    |> cast_embed(:low)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
