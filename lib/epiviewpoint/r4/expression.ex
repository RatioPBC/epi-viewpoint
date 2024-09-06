defmodule Epiviewpoint.R4.Expression do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :description,
    :expression,
    :id,
    :language,
    :name,
    :reference
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:description, :string)
    field(:expression, :string)
    field(:name, :binary_id)
    field(:reference, :string)

    # Enum
    field(:language, Ecto.Enum,
      values: [
        :"text/cql",
        :"text/fhirpath",
        :"application/x_fhir_query"
      ]
    )

    # Embed Many
    embeds_many(:extension, Epiviewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end