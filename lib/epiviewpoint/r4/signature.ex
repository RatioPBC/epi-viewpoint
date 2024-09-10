defmodule EpiViewpoint.R4.Signature do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :data,
    :id,
    :sig_format,
    :target_format,
    :when
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:data, :string)
    field(:sig_format, :string)
    field(:target_format, :string)
    field(:when, :utc_datetime_usec)

    # Embed One
    embeds_one(:on_behalf_of, EpiViewpoint.R4.Reference)
    embeds_one(:who, EpiViewpoint.R4.Reference)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
    embeds_many(:type, EpiViewpoint.R4.Coding)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:on_behalf_of)
    |> cast_embed(:who)
    |> cast_embed(:extension)
    |> cast_embed(:type)
    |> validate_required(@required_fields)
  end
end
