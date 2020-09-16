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
    |> unique_constraint([:person_id, :full_address], name: :addresses_full_address_person_id_index)
  end

  defmodule Query do
    def display_order() do
      from a in Address,
        order_by: [fragment("case when is_preferred=true then 0 else 1 end"), asc_nulls_last: :full_address]
    end

    def order_by_full_address(direction) do
      from(a in Address, order_by: [{^direction, :full_address}])
    end

    def opts_for_upsert() do
      [returning: true, on_conflict: {:replace, ~w{updated_at}a}, conflict_target: [:person_id, :full_address]]
    end
  end
end
