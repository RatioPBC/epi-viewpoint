defmodule EpiViewpoint.R4.Narrative do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :div,
    :id,
    :status
  ]
  @required_fields [
    :div
  ]

  embedded_schema do
    # Fields
    field(:div, :string)

    # Enum
    field(:status, Ecto.Enum,
      values: [
        :generated,
        :extensions,
        :additional,
        :empty
      ]
    )

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
