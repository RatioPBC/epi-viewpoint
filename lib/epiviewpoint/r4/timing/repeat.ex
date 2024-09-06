defmodule Epiviewpoint.R4.Timing.Repeat do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :day_of_week,
    :duration_unit,
    :count,
    :count_max,
    :period_unit,
    :when,
    :frequency,
    :period_max,
    :duration_max,
    :time_of_day,
    :duration,
    :frequency_max,
    :offset,
    :period,
    :id
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:count, :integer)
    field(:count_max, :integer)
    field(:frequency, :integer)
    field(:period_max, :decimal)
    field(:duration_max, :decimal)
    field(:duration, :decimal)
    field(:frequency_max, :integer)
    field(:offset, :integer)
    field(:period, :decimal)

    field(:day_of_week, {:array, :string})
    field(:when, {:array, :string})
    field(:time_of_day, {:array, :time_usec})

    # Enum
    field(:duration_unit, Ecto.Enum,
      values: [
        :s,
        :min,
        :h,
        :d,
        :wk,
        :mo,
        :a
      ]
    )

    field(:period_unit, Ecto.Enum,
      values: [
        :s,
        :min,
        :h,
        :d,
        :wk,
        :mo,
        :a
      ]
    )

    # Embed One
    embeds_one(:bounds_duration, Epiviewpoint.R4.Duration)
    embeds_one(:bounds_range, Epiviewpoint.R4.Range)
    embeds_one(:bounds_period, Epiviewpoint.R4.Period)

    # Embed Many
    embeds_many(:extension, Epiviewpoint.R4.Extension)
    embeds_many(:modifier_extension, Epiviewpoint.R4.Extension)
  end

  def choices("bounds") do
    [:bounds_duration, :bounds_range, :bounds_period]
  end

  def choices("boundsDuration"), do: :error

  def choices("boundsRange"), do: :error

  def choices("boundsPeriod"), do: :error

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:bounds_duration)
    |> cast_embed(:bounds_range)
    |> cast_embed(:bounds_period)
    |> cast_embed(:extension)
    |> cast_embed(:modifier_extension)
    |> validate_required(@required_fields)
  end
end