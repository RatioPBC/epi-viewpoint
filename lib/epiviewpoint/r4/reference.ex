defmodule EpiViewpoint.R4.Reference do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :display,
    :id,
    :reference,
    :type
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:display, :string)
    field(:reference, :string)
    field(:type, :string)

    # Embed One
    embeds_one(:identifier, EpiViewpoint.R4.Identifier)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:identifier)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
