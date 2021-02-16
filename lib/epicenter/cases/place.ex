defmodule Epicenter.Cases.Place do
  use Ecto.Schema
  import Ecto.Changeset

  @required_attrs ~w{}a
  @optional_attrs ~w{name type}a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "places" do
    field :name, :string
    field :seq, :integer, read_after_writes: true
    field :tid, :string
    field :type, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(place, attrs) do
    place
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
  end
end
