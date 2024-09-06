defmodule Epiviewpoint.R4.ResourceList do
  use Ecto.Schema
  import Ecto.Changeset

  @fields []
  @required_fields []

  embedded_schema do
  end

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end