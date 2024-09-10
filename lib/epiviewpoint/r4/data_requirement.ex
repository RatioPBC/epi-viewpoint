defmodule EpiViewpoint.R4.DataRequirement do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :limit,
    :must_support,
    :profile,
    :type
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:limit, :integer)
    field(:type, :string)

    field(:must_support, {:array, :string})
    field(:profile, {:array, :string})

    # Embed One
    embeds_one(:subject_codeable_concept, EpiViewpoint.R4.CodeableConcept)
    embeds_one(:subject_reference, EpiViewpoint.R4.Reference)

    # Embed Many
    embeds_many(:code_filter, EpiViewpoint.R4.DataRequirement.CodeFilter)
    embeds_many(:date_filter, EpiViewpoint.R4.DataRequirement.DateFilter)
    embeds_many(:extension, EpiViewpoint.R4.Extension)
    embeds_many(:sort, EpiViewpoint.R4.DataRequirement.Sort)
  end

  def choices("subject") do
    [:subject_codeable_concept, :subject_reference]
  end

  def choices("subjectCodeableConcept"), do: :error

  def choices("subjectReference"), do: :error

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:subject_codeable_concept)
    |> cast_embed(:subject_reference)
    |> cast_embed(:code_filter)
    |> cast_embed(:date_filter)
    |> cast_embed(:extension)
    |> cast_embed(:sort)
    |> validate_required(@required_fields)
  end
end
