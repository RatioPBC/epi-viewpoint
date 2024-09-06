defmodule Epiviewpoint.R4.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :content_type,
    :creation,
    :data,
    :hash,
    :id,
    :language,
    :size,
    :title,
    :url
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:content_type, :string)
    field(:creation, :utc_datetime_usec)
    field(:data, :string)
    field(:hash, :string)
    field(:language, :string)
    field(:size, :integer)
    field(:title, :string)
    field(:url, :string)

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