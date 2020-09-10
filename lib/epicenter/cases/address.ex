defmodule Epicenter.Cases.Address do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  import Epicenter.Validation, only: [validate_phi: 2]

  alias Epicenter.Cases.Address

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "addresses" do
    field :full_address, :string
    field :seq, :integer
    field :tid, :string
    field :type, :string
    field :person_id, :binary_id
    field :is_preferred, :boolean

    timestamps()
  end

  @required_attrs ~w{full_address person_id}a
  @optional_attrs ~w(type tid is_preferred)a

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_phi(:address)
  end

  defmodule Query do
    def order_by_full_address(direction) do
      from(a in Address, order_by: [{^direction, :full_address}])
    end
  end
end
