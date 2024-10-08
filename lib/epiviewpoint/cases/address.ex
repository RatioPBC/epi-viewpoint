defmodule EpiViewpoint.Cases.Address do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  import EpiViewpoint.PhiValidation, only: [validate_phi: 2]

  alias EpiViewpoint.Cases.Address
  alias EpiViewpoint.Extra

  @required_attrs ~w{}a
  @optional_attrs ~w(delete street city state postal_code type tid is_preferred person_id source)a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "addresses" do
    field :address_fingerprint, :string, read_after_writes: true
    field :delete, :boolean, virtual: true
    field :street, :string
    field :city, :string
    field :state, :string
    field :postal_code, :string
    field :seq, :integer, read_after_writes: true
    field :source, :string
    field :tid, :string
    field :type, :string
    field :person_id, :binary_id
    field :is_preferred, :boolean

    timestamps(type: :utc_datetime)
  end

  def changeset(address, attrs) do
    address
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_phi(:address)
    |> unique_constraint([:person_id, :address_fingerprint], name: :addresses_address_fingerprint_person_id_index)
    |> Extra.Changeset.maybe_mark_for_deletion()
  end

  def to_comparable_string(%Address{} = address) do
    [address.street, address.city, address.state, address.postal_code]
    |> Euclid.Extra.Enum.compact()
    |> Enum.map(fn s -> s |> Extra.String.squish() |> Extra.String.trim() |> String.downcase() end)
    |> Enum.join(" ")
  end

  defmodule Query do
    def display_order() do
      from a in Address,
        order_by: [
          fragment("case when is_preferred=true then 0 else 1 end"),
          {:asc_nulls_last, :street},
          {:asc_nulls_last, :city},
          {:asc_nulls_last, :state},
          {:asc_nulls_last, :postal_code}
        ]
    end

    def order_by_full_address(direction) do
      from(a in Address, order_by: [{^direction, :street}, {^direction, :city}, {^direction, :state}, {^direction, :postal_code}])
    end

    def opts_for_upsert() do
      [returning: true, on_conflict: {:replace, ~w{updated_at}a}, conflict_target: [:person_id, :address_fingerprint]]
    end
  end
end
