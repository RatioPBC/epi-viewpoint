defmodule Epiviewpoint.R4.DataRequirement.DateFilter do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :path,
    :search_param,
    :value_date_time
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:path, :string)
    field(:search_param, :string)
    field(:value_date_time, :string)

    # Embed One
    embeds_one(:value_duration, Epiviewpoint.R4.Duration)
    embeds_one(:value_period, Epiviewpoint.R4.Period)

    # Embed Many
    embeds_many(:extension, Epiviewpoint.R4.Extension)
    embeds_many(:modifier_extension, Epiviewpoint.R4.Extension)
  end

  def choices("value") do
    [:value_date_time, :value_period, :value_duration]
  end

  def choices("valuedateTime"), do: :error

  def choices("valuePeriod"), do: :error

  def choices("valueDuration"), do: :error

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:value_duration)
    |> cast_embed(:value_period)
    |> cast_embed(:extension)
    |> cast_embed(:modifier_extension)
    |> validate_required(@required_fields)
  end
end