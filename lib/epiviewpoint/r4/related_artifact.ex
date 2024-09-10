defmodule EpiViewpoint.R4.RelatedArtifact do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :citation,
    :display,
    :id,
    :label,
    :resource,
    :type,
    :url
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:citation, :string)
    field(:display, :string)
    field(:label, :string)
    field(:resource, :string)
    field(:url, :string)

    # Enum
    field(:type, Ecto.Enum,
      values: [
        :documentation,
        :justification,
        :citation,
        :predecessor,
        :successor,
        :derived_from,
        :depends_on,
        :composed_of
      ]
    )

    # Embed One
    embeds_one(:document, EpiViewpoint.R4.Attachment)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:document)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
