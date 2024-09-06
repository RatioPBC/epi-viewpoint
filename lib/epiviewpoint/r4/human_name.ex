defmodule EpiViewpoint.R4.HumanName do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :family,
    :given,
    :id,
    :prefix,
    :suffix,
    :text,
    :use
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:family, :string)
    field(:text, :string)

    field(:given, {:array, :string})
    field(:prefix, {:array, :string})
    field(:suffix, {:array, :string})

    # Enum
    field(:use, Ecto.Enum,
      values: [
        :usual,
        :official,
        :temp,
        :nickname,
        :anonymous,
        :old,
        :maiden
      ]
    )

    # Embed One
    embeds_one(:period, EpiViewpoint.R4.Period)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:period)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
