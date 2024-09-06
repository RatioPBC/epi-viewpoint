defmodule Epiviewpoint.R4.Observation.Component do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :value_boolean,
    :value_date_time,
    :value_integer,
    :value_string,
    :value_time
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:value_boolean, :boolean)
    field(:value_date_time, :string)
    field(:value_integer, :integer)
    field(:value_string, :string)
    field(:value_time, :string)

    # Embed One
    embeds_one(:code, Epiviewpoint.R4.CodeableConcept)
    embeds_one(:data_absent_reason, Epiviewpoint.R4.CodeableConcept)
    embeds_one(:value_codeable_concept, Epiviewpoint.R4.CodeableConcept)
    embeds_one(:value_period, Epiviewpoint.R4.Period)
    embeds_one(:value_quantity, Epiviewpoint.R4.Quantity)
    embeds_one(:value_range, Epiviewpoint.R4.Range)
    embeds_one(:value_ratio, Epiviewpoint.R4.Ratio)
    embeds_one(:value_sampled_data, Epiviewpoint.R4.SampledData)

    # Embed Many
    embeds_many(:extension, Epiviewpoint.R4.Extension)
    embeds_many(:interpretation, Epiviewpoint.R4.CodeableConcept)
    embeds_many(:modifier_extension, Epiviewpoint.R4.Extension)
    embeds_many(:reference_range, Epiviewpoint.R4.Observation.ReferenceRange)
  end

  def choices("value") do
    [
      :value_quantity,
      :value_codeable_concept,
      :value_string,
      :value_boolean,
      :value_integer,
      :value_range,
      :value_ratio,
      :value_sampled_data,
      :value_time,
      :value_date_time,
      :value_period
    ]
  end

  def choices("valueQuantity"), do: :error

  def choices("valueCodeableConcept"), do: :error

  def choices("valuestring"), do: :error

  def choices("valueboolean"), do: :error

  def choices("valueinteger"), do: :error

  def choices("valueRange"), do: :error

  def choices("valueRatio"), do: :error

  def choices("valueSampledData"), do: :error

  def choices("valuetime"), do: :error

  def choices("valuedateTime"), do: :error

  def choices("valuePeriod"), do: :error

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:code)
    |> cast_embed(:data_absent_reason)
    |> cast_embed(:value_codeable_concept)
    |> cast_embed(:value_period)
    |> cast_embed(:value_quantity)
    |> cast_embed(:value_range)
    |> cast_embed(:value_ratio)
    |> cast_embed(:value_sampled_data)
    |> cast_embed(:extension)
    |> cast_embed(:interpretation)
    |> cast_embed(:modifier_extension)
    |> cast_embed(:reference_range)
    |> validate_required(@required_fields)
  end
end