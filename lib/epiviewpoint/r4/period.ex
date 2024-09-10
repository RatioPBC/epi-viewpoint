defmodule EpiViewpoint.R4.Period do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :end,
    :id,
    :start
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:end, :utc_datetime_usec)
    field(:start, :utc_datetime_usec)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
