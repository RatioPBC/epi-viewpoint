defmodule EpiViewpoint.R4.Address do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :city,
    :country,
    :district,
    :id,
    :line,
    :postal_code,
    :state,
    :text,
    :type,
    :use
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:city, :string)
    field(:country, :string)
    field(:district, :string)
    field(:postal_code, :string)
    field(:state, :string)
    field(:text, :string)

    field(:line, {:array, :string})

    # Enum
    field(:type, Ecto.Enum,
      values: [
        :postal,
        :physical,
        :both
      ]
    )

    field(:use, Ecto.Enum,
      values: [
        :home,
        :work,
        :temp,
        :old,
        :billing
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
