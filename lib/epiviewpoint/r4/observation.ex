defmodule EpiViewpoint.R4.Observation do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :value_time,
    :effective_date_time,
    :value_date_time,
    :effective_instant,
    :value_string,
    :language,
    :value_integer,
    :implicit_rules,
    :status,
    :id,
    :issued,
    :value_boolean
  ]
  @required_fields []

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "observation" do
    # Constants
    field(:resource_type, :string, virtual: true, default: "Observation")

    # Fields
    field(:value_time, :string)
    field(:effective_date_time, :string)
    field(:value_date_time, :string)
    field(:effective_instant, :string)
    field(:value_string, :string)
    field(:language, :string)
    field(:value_integer, :integer)
    field(:implicit_rules, :string)
    field(:issued, :utc_datetime_usec)
    field(:value_boolean, :boolean)

    # Enum
    field(:status, Ecto.Enum,
      values: [
        :registered,
        :preliminary,
        :final,
        :amended,
        :corrected,
        :cancelled,
        :entered_in_error,
        :unknown
      ]
    )

    # Embed One
    embeds_one(:value_quantity, EpiViewpoint.R4.Quantity)
    embeds_one(:effective_timing, EpiViewpoint.R4.Timing)
    embeds_one(:value_sampled_data, EpiViewpoint.R4.SampledData)
    embeds_one(:specimen, EpiViewpoint.R4.Reference)
    embeds_one(:effective_period, EpiViewpoint.R4.Period)
    embeds_one(:value_ratio, EpiViewpoint.R4.Ratio)
    embeds_one(:encounter, EpiViewpoint.R4.Reference)
    embeds_one(:code, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:subject, EpiViewpoint.R4.Reference)
    embeds_one(:data_absent_reason, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:text, EpiViewpoint.R4.Narrative)
    embeds_one(:body_site, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:meta, EpiViewpoint.R4.Meta)
    embeds_one(:value_period, EpiViewpoint.R4.Period)
    embeds_one(:value_range, EpiViewpoint.R4.Range)
    embeds_one(:method, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:device, EpiViewpoint.R4.Reference)
    embeds_one(:value_codeable_concept, EpiViewpoint.R4.CodeableConcept)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
    embeds_many(:contained, EpiViewpoint.R4.ResourceList)
    embeds_many(:reference_range, EpiViewpoint.R4.Observation.ReferenceRange)
    embeds_many(:derived_from, EpiViewpoint.R4.Reference)
    embeds_many(:focus, EpiViewpoint.R4.Reference)
    embeds_many(:based_on, EpiViewpoint.R4.Reference)
    embeds_many(:component, EpiViewpoint.R4.Observation.Component)
    embeds_many(:performer, EpiViewpoint.R4.Reference)
    embeds_many(:modifier_extension, EpiViewpoint.R4.Extension)
    embeds_many(:identifier, EpiViewpoint.R4.Identifier)
    embeds_many(:part_of, EpiViewpoint.R4.Reference)
    embeds_many(:has_member, EpiViewpoint.R4.Reference)
    embeds_many(:category, EpiViewpoint.R4.CodeableConcept)
    embeds_many(:note, EpiViewpoint.R4.Annotation)
    embeds_many(:interpretation, EpiViewpoint.R4.CodeableConcept)
  end

  def choices("effective") do
    [:effective_date_time, :effective_period, :effective_timing, :effective_instant]
  end

  def choices("effectivedateTime"), do: :error

  def choices("effectivePeriod"), do: :error

  def choices("effectiveTiming"), do: :error

  def choices("effectiveinstant"), do: :error

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

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"
  def path, do: "/Observation"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:value_quantity)
    |> cast_embed(:effective_timing)
    |> cast_embed(:value_sampled_data)
    |> cast_embed(:specimen)
    |> cast_embed(:effective_period)
    |> cast_embed(:value_ratio)
    |> cast_embed(:encounter)
    |> cast_embed(:code)
    |> cast_embed(:subject)
    |> cast_embed(:data_absent_reason)
    |> cast_embed(:text)
    |> cast_embed(:body_site)
    |> cast_embed(:meta)
    |> cast_embed(:value_period)
    |> cast_embed(:value_range)
    |> cast_embed(:method)
    |> cast_embed(:device)
    |> cast_embed(:value_codeable_concept)
    |> cast_embed(:extension)
    |> cast_embed(:contained)
    |> cast_embed(:reference_range)
    |> cast_embed(:derived_from)
    |> cast_embed(:focus)
    |> cast_embed(:based_on)
    |> cast_embed(:component)
    |> cast_embed(:performer)
    |> cast_embed(:modifier_extension)
    |> cast_embed(:identifier)
    |> cast_embed(:part_of)
    |> cast_embed(:has_member)
    |> cast_embed(:category)
    |> cast_embed(:note)
    |> cast_embed(:interpretation)
    |> validate_required(@required_fields)
  end
end
