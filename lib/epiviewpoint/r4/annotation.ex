defmodule EpiViewpoint.R4.Annotation do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :author_string,
    :id,
    :text,
    :time
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:author_string, :string)
    field(:text, :string)
    field(:time, :utc_datetime_usec)

    # Embed One
    embeds_one(:author_reference, EpiViewpoint.R4.Reference)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices("author") do
    [:author_reference, :author_string]
  end

  def choices("authorReference"), do: :error

  def choices("authorstring"), do: :error

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:author_reference)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
