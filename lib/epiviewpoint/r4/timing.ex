defmodule EpiViewpoint.R4.Timing do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :event,
    :id
  ]
  @required_fields []

  embedded_schema do
    field(:event, {:array, :utc_datetime_usec})

    # Embed One
    embeds_one(:code, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:repeat, EpiViewpoint.R4.Timing.Repeat)

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
    |> cast_embed(:code)
    |> cast_embed(:repeat)
    |> cast_embed(:extension)
    |> cast_embed(:modifier_extension)
    |> validate_required(@required_fields)
  end
end
