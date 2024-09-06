defmodule EpiViewpoint.R4.SampledData do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :data,
    :dimensions,
    :factor,
    :id,
    :lower_limit,
    :period,
    :upper_limit
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:data, :string)
    field(:dimensions, :integer)
    field(:factor, :decimal)
    field(:lower_limit, :decimal)
    field(:period, :decimal)
    field(:upper_limit, :decimal)

    # Embed One
    embeds_one(:origin, EpiViewpoint.R4.Quantity)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:origin)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
