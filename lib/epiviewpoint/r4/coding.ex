defmodule EpiViewpoint.R4.Coding do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :code,
    :display,
    :id,
    :system,
    :user_selected,
    :version
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:code, :string)
    field(:display, :string)
    field(:system, :string)
    field(:user_selected, :boolean)
    field(:version, :string)

    # Embed Many
    embeds_many(:extension, EpiViewpoint.R4.Extension)
  end

  def choices(_), do: nil

  def version_namespace, do: EpiViewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end
