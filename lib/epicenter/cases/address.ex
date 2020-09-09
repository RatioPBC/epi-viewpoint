defmodule Epicenter.Cases.Address do
  use Ecto.Schema
  import Ecto.Changeset
  import Epicenter.Validation, only: [validate_phi: 2]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "addresses" do
    field :full_address, :string
    field :seq, :integer
    field :tid, :string
    field :type, :string
    field :person_id, :binary_id

    timestamps()
  end

  @required_attrs ~w{full_address person_id}a
  @optional_attrs ~w(type tid)a

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_phi(:address)
  end
end
