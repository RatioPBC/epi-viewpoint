defmodule EpiViewpoint.R4.ParameterDefinition do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :documentation,
    :id,
    :max,
    :min,
    :name,
    :profile,
    :type,
    :use
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:documentation, :string)
    field(:max, :string)
    field(:min, :integer)
    field(:name, :string)
    field(:profile, :string)
    field(:type, :string)
    field(:use, :string)

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
