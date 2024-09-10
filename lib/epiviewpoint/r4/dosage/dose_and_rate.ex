defmodule EpiViewpoint.R4.Dosage.DoseAndRate do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id
  ]
  @required_fields []

  embedded_schema do
    # Embed One
    embeds_one(:dose_quantity, EpiViewpoint.R4.Quantity)
    embeds_one(:dose_range, EpiViewpoint.R4.Range)
    embeds_one(:rate_quantity, EpiViewpoint.R4.Quantity)
    embeds_one(:rate_range, EpiViewpoint.R4.Range)
    embeds_one(:rate_ratio, EpiViewpoint.R4.Ratio)
    embeds_one(:type, EpiViewpoint.R4.CodeableConcept)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
    embeds_many(:modifier_extension, EpiViewpoint.R4.Extension)
  end

  def choices("dose") do
    [:dose_range, :dose_simple_quantity]
  end

  def choices("doseRange"), do: :error

  def choices("doseSimpleQuantity"), do: :error

  def choices("rate") do
    [:rate_ratio, :rate_range, :rate_simple_quantity]
  end

  def choices("rateRatio"), do: :error

  def choices("rateRange"), do: :error

  def choices("rateSimpleQuantity"), do: :error

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:dose_quantity)
    |> cast_embed(:dose_range)
    |> cast_embed(:rate_quantity)
    |> cast_embed(:rate_range)
    |> cast_embed(:rate_ratio)
    |> cast_embed(:type)
    |> cast_embed(:extension)
    |> cast_embed(:modifier_extension)
    |> validate_required(@required_fields)
  end
end
