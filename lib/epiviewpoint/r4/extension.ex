defmodule EpiViewpoint.R4.Extension do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :value_time,
    :value_positive_int,
    :value_date_time,
    :value_markdown,
    :value_date,
    :value_unsigned_int,
    :value_string,
    :value_url,
    :value_uri,
    :value_integer,
    :value_canonical,
    :value_instant,
    :url,
    :value_oid,
    :value_code,
    :value_base64_binary,
    :value_decimal,
    :id,
    :value_uuid,
    :value_boolean,
    :value_id
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:value_time, :string)
    field(:value_positive_int, :integer)
    field(:value_date_time, :string)
    field(:value_markdown, :string)
    field(:value_date, :string)
    field(:value_unsigned_int, :integer)
    field(:value_string, :string)
    field(:value_url, :string)
    field(:value_uri, :string)
    field(:value_integer, :integer)
    field(:value_canonical, :string)
    field(:value_instant, :string)
    field(:url, :string)
    field(:value_oid, :string)
    field(:value_code, :string)
    field(:value_base64_binary, :string)
    field(:value_decimal, :decimal)
    field(:value_uuid, :string)
    field(:value_boolean, :boolean)
    field(:value_id, :string)

    # Embed One
    embeds_one(:value_quantity, EpiViewpoint.R4.Quantity)
    embeds_one(:value_expression, EpiViewpoint.R4.Expression)
    embeds_one(:value_attachment, EpiViewpoint.R4.Attachment)
    embeds_one(:value_identifier, EpiViewpoint.R4.Identifier)
    embeds_one(:value_sampled_data, EpiViewpoint.R4.SampledData)
    embeds_one(:value_parameter_definition, EpiViewpoint.R4.ParameterDefinition)
    embeds_one(:value_timing, EpiViewpoint.R4.Timing)
    embeds_one(:value_reference, EpiViewpoint.R4.Reference)
    embeds_one(:value_contact_point, EpiViewpoint.R4.ContactPoint)
    embeds_one(:value_age, EpiViewpoint.R4.Age)
    embeds_one(:value_meta, EpiViewpoint.R4.Meta)
    embeds_one(:value_annotation, EpiViewpoint.R4.Annotation)
    embeds_one(:value_money, EpiViewpoint.R4.Money)
    embeds_one(:value_usage_context, EpiViewpoint.R4.UsageContext)
    embeds_one(:value_related_artifact, EpiViewpoint.R4.RelatedArtifact)
    embeds_one(:value_contact_detail, EpiViewpoint.R4.ContactDetail)
    embeds_one(:value_ratio, EpiViewpoint.R4.Ratio)
    embeds_one(:value_distance, EpiViewpoint.R4.Distance)
    embeds_one(:value_duration, EpiViewpoint.R4.Duration)
    embeds_one(:value_human_name, EpiViewpoint.R4.HumanName)
    embeds_one(:value_period, EpiViewpoint.R4.Period)
    embeds_one(:value_range, EpiViewpoint.R4.Range)
    embeds_one(:value_dosage, EpiViewpoint.R4.Dosage)
    embeds_one(:value_contributor, EpiViewpoint.R4.Contributor)
    embeds_one(:value_address, EpiViewpoint.R4.Address)
    embeds_one(:value_signature, EpiViewpoint.R4.Signature)
    embeds_one(:value_trigger_definition, EpiViewpoint.R4.TriggerDefinition)
    embeds_one(:value_data_requirement, EpiViewpoint.R4.DataRequirement)
    embeds_one(:value_count, EpiViewpoint.R4.Count)
    embeds_one(:value_coding, EpiViewpoint.R4.Coding)
    embeds_one(:value_codeable_concept, EpiViewpoint.R4.CodeableConcept)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:value_quantity)
    |> cast_embed(:value_expression)
    |> cast_embed(:value_attachment)
    |> cast_embed(:value_identifier)
    |> cast_embed(:value_sampled_data)
    |> cast_embed(:value_parameter_definition)
    |> cast_embed(:value_timing)
    |> cast_embed(:value_reference)
    |> cast_embed(:value_contact_point)
    |> cast_embed(:value_age)
    |> cast_embed(:value_meta)
    |> cast_embed(:value_annotation)
    |> cast_embed(:value_money)
    |> cast_embed(:value_usage_context)
    |> cast_embed(:value_related_artifact)
    |> cast_embed(:value_contact_detail)
    |> cast_embed(:value_ratio)
    |> cast_embed(:value_distance)
    |> cast_embed(:value_duration)
    |> cast_embed(:value_human_name)
    |> cast_embed(:value_period)
    |> cast_embed(:value_range)
    |> cast_embed(:value_dosage)
    |> cast_embed(:value_contributor)
    |> cast_embed(:value_address)
    |> cast_embed(:value_signature)
    |> cast_embed(:value_trigger_definition)
    |> cast_embed(:value_data_requirement)
    |> cast_embed(:value_count)
    |> cast_embed(:value_coding)
    |> cast_embed(:value_codeable_concept)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
