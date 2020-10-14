defmodule Epicenter.Cases.Ethnicity do
  use Ecto.Schema
  import Ecto.Changeset

  @attrs ~w{parent children}a

  @derive {Jason.Encoder, only: @attrs}

  @primary_key false
  embedded_schema do
    field :parent, :string
    field :children, {:array, :string}
  end

  def changeset(changeset, attrs) do
    changeset |> cast(attrs, [:parent, :children])
  end
end
