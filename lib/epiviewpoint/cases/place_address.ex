defmodule EpiViewpoint.Cases.PlaceAddress do
  use Ecto.Schema
  import Ecto.Changeset
  import EpiViewpoint.PhiValidation, only: [validate_phi: 2]

  alias EpiViewpoint.Cases.Place
  alias EpiViewpoint.Cases.PlaceAddress
  alias EpiViewpoint.Extra

  @required_attrs ~w{}a
  @optional_attrs ~w{city place_id postal_code state street street_2 tid}a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "place_addresses" do
    field :address_fingerprint, :string, read_after_writes: true
    field :city, :string
    field :postal_code, :string
    field :seq, :integer, read_after_writes: true
    field :state, :string
    field :street, :string
    field :street_2, :string
    field :tid, :string

    belongs_to :place, Place

    timestamps(type: :utc_datetime)
  end

  def changeset(place, attrs) do
    place
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> validate_phi(:address)
  end

  def to_comparable_string(%PlaceAddress{} = address) do
    [address.street, address.street_2, address.city, address.state, address.postal_code]
    |> Euclid.Extra.Enum.compact()
    |> Enum.map(fn s -> s |> Extra.String.squish() |> Extra.String.trim() |> String.downcase() end)
    |> Enum.join(" ")
  end
end
