defmodule EpiViewpoint.R4.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :active,
    :alias,
    :id,
    :implicit_rules,
    :language,
    :name
  ]
  @required_fields []

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "organization" do
    # Constants
    field(:resource_type, :string, virtual: true, default: "Organization")

    # Fields
    field(:active, :boolean)
    field(:implicit_rules, :string)
    field(:language, :string)
    field(:name, :string)

    field(:alias, {:array, :string})

    # Embed One
    embeds_one(:meta, EpiViewpoint.R4.Meta)
    embeds_one(:part_of, EpiViewpoint.R4.Reference)
    embeds_one(:text, EpiViewpoint.R4.Narrative)

    # Embed Many
    embeds_many(:address, EpiViewpoint.R4.Address)
    embeds_many(:contact, EpiViewpoint.R4.Organization.Contact)
    embeds_many(:contained, EpiViewpoint.R4.ResourceList)
    embeds_many(:endpoint, EpiViewpoint.R4.Reference)
    embeds_many(:extension, EpiViewpoint.R4.Extension)
    embeds_many(:identifier, EpiViewpoint.R4.Identifier)
    embeds_many(:modifier_extension, EpiViewpoint.R4.Extension)
    embeds_many(:telecom, EpiViewpoint.R4.ContactPoint)
    embeds_many(:type, EpiViewpoint.R4.CodeableConcept)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"
  def path, do: "/Organization"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:meta)
    |> cast_embed(:part_of)
    |> cast_embed(:text)
    |> cast_embed(:address)
    |> cast_embed(:contact)
    |> cast_embed(:contained)
    |> cast_embed(:endpoint)
    |> cast_embed(:extension)
    |> cast_embed(:identifier)
    |> cast_embed(:modifier_extension)
    |> cast_embed(:telecom)
    |> cast_embed(:type)
    |> validate_required(@required_fields)
  end
end
