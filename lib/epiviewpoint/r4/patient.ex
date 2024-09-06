defmodule Epiviewpoint.R4.Patient do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :active,
    :multiple_birth_boolean,
    :language,
    :implicit_rules,
    :birth_date,
    :multiple_birth_integer,
    :id,
    :deceased_boolean,
    :gender,
    :deceased_date_time
  ]
  @required_fields []

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "patient" do
    # Constants
    field(:resource_type, :string, virtual: true, default: "Patient")

    # Fields
    field(:active, :boolean)
    field(:multiple_birth_boolean, :boolean)
    field(:language, :string)
    field(:implicit_rules, :string)
    field(:birth_date, :date)
    field(:multiple_birth_integer, :integer)
    field(:deceased_boolean, :boolean)
    field(:deceased_date_time, :string)

    # Enum
    field(:gender, Ecto.Enum,
      values: [
        :male,
        :female,
        :other,
        :unknown
      ]
    )

    # Embed One
    embeds_one(:marital_status, Epiviewpoint.R4.CodeableConcept)
    embeds_one(:managing_organization, Epiviewpoint.R4.Reference)
    embeds_one(:text, Epiviewpoint.R4.Narrative)
    embeds_one(:meta, Epiviewpoint.R4.Meta)

    # Embed Many
    embeds_many(:photo, Epiviewpoint.R4.Attachment)
    embeds_many(:communication, Epiviewpoint.R4.Patient.Communication)
    embeds_many(:name, Epiviewpoint.R4.HumanName)
    embeds_many(:extension, Epiviewpoint.R4.Extension)
    embeds_many(:telecom, Epiviewpoint.R4.ContactPoint)
    embeds_many(:contained, Epiviewpoint.R4.ResourceList)
    embeds_many(:link, Epiviewpoint.R4.Patient.Link)
    embeds_many(:contact, Epiviewpoint.R4.Patient.Contact)
    embeds_many(:modifier_extension, Epiviewpoint.R4.Extension)
    embeds_many(:identifier, Epiviewpoint.R4.Identifier)
    embeds_many(:general_practitioner, Epiviewpoint.R4.Reference)
    embeds_many(:address, Epiviewpoint.R4.Address)
  end

  def choices("deceased") do
    [:deceased_boolean, :deceased_date_time]
  end

  def choices("deceasedboolean"), do: :error

  def choices("deceaseddateTime"), do: :error

  def choices("multipleBirth") do
    [:multipleBirth_boolean, :multipleBirth_integer]
  end

  def choices("multipleBirthboolean"), do: :error

  def choices("multipleBirthinteger"), do: :error

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"
  def path, do: "/Patient"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:marital_status)
    |> cast_embed(:managing_organization)
    |> cast_embed(:text)
    |> cast_embed(:meta)
    |> cast_embed(:photo)
    |> cast_embed(:communication)
    |> cast_embed(:name)
    |> cast_embed(:extension)
    |> cast_embed(:telecom)
    |> cast_embed(:contained)
    |> cast_embed(:link)
    |> cast_embed(:contact)
    |> cast_embed(:modifier_extension)
    |> cast_embed(:identifier)
    |> cast_embed(:general_practitioner)
    |> cast_embed(:address)
    |> validate_required(@required_fields)
  end
end