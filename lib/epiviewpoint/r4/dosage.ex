defmodule EpiViewpoint.R4.Dosage do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :as_needed_boolean,
    :id,
    :patient_instruction,
    :sequence,
    :text
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:as_needed_boolean, :boolean)
    field(:patient_instruction, :string)
    field(:sequence, :integer)
    field(:text, :string)

    # Embed One
    embeds_one(:as_needed_codeable_concept, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:max_dose_per_administration, EpiViewpoint.R4.Quantity)
    embeds_one(:max_dose_per_lifetime, EpiViewpoint.R4.Quantity)
    embeds_one(:max_dose_per_period, EpiViewpoint.R4.Ratio)
    embeds_one(:method, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:route, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:site, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:timing, EpiViewpoint.R4.Timing)

    # Embed Many
    embeds_many(:additional_instruction, EpiViewpoint.R4.CodeableConcept)
    embeds_many(:dose_and_rate, EpiViewpoint.R4.Dosage.DoseAndRate)
    embeds_many(:extension, EpiViewpoint.R4.Extension)
    embeds_many(:modifier_extension, EpiViewpoint.R4.Extension)
  end

  def choices("asNeeded") do
    [:asNeeded_boolean, :asNeeded_codeable_concept]
  end

  def choices("asNeededboolean"), do: :error

  def choices("asNeededCodeableConcept"), do: :error

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:as_needed_codeable_concept)
    |> cast_embed(:max_dose_per_administration)
    |> cast_embed(:max_dose_per_lifetime)
    |> cast_embed(:max_dose_per_period)
    |> cast_embed(:method)
    |> cast_embed(:route)
    |> cast_embed(:site)
    |> cast_embed(:timing)
    |> cast_embed(:additional_instruction)
    |> cast_embed(:dose_and_rate)
    |> cast_embed(:extension)
    |> cast_embed(:modifier_extension)
    |> validate_required(@required_fields)
  end
end
