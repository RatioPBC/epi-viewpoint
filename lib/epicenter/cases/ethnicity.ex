defmodule Epicenter.Cases.Ethnicity do
  use Ecto.Schema
  import Ecto.Changeset

  @attrs ~w{major detailed}a

  @derive {Jason.Encoder, only: @attrs}

  @primary_key false
  embedded_schema do
    field :major, :string
    field :detailed, {:array, :string}
  end

  def changeset(changeset, attrs) do
    changeset |> cast(attrs, @attrs)
  end
end
