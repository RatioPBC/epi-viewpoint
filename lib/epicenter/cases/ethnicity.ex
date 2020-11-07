defmodule Epicenter.Cases.Ethnicity do
  use Ecto.Schema
  import Ecto.Changeset
  alias Epicenter.Cases.Ethnicity

  @attrs ~w{major detailed}a

  @derive {Jason.Encoder, only: @attrs}

  @primary_key false
  embedded_schema do
    field :major, :string
    field :detailed, {:array, :string}
  end

  def changeset(changeset, attrs),
    do: changeset |> cast(attrs, @attrs)

  def major(nil),
    do: nil

  def major(%Ethnicity{major: major}),
    do: major

  def hispanic_latinx_or_spanish_origin(%Ethnicity{major: "hispanic_latinx_or_spanish_origin", detailed: detailed}),
    do: detailed

  def hispanic_latinx_or_spanish_origin(_other),
    do: nil
end
