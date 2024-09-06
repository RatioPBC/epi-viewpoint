defmodule EpiViewpoint.R4.Contributor do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :name,
    :type
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:name, :string)

    # Enum
    field(:type, Ecto.Enum,
      values: [
        :author,
        :editor,
        :reviewer,
        :endorser
      ]
    )

    # Embed Many
    embeds_many(:contact, EpiViewpoint.R4.ContactDetail)
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:contact)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
