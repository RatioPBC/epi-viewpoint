defmodule EpiViewpoint.Cases.Place do
  use Ecto.Schema
  import Ecto.Changeset
  import EpiViewpoint.PhiValidation, only: [validate_phi: 2]

  alias Ecto.Multi
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Place
  alias EpiViewpoint.Cases.PlaceAddress

  @required_attrs ~w{}a
  @optional_attrs ~w{name tid type contact_name contact_phone contact_email}a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "places" do
    field :name, :string
    field :seq, :integer, read_after_writes: true
    field :tid, :string
    field :type, :string
    field :contact_name, :string
    field :contact_phone, :string
    field :contact_email, :string

    timestamps(type: :utc_datetime)

    has_many :place_addresses, PlaceAddress
  end

  def changeset(place, attrs) do
    place
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> cast_assoc(:place_addresses, with: &PlaceAddress.changeset/2)
    |> EpiViewpoint.PhoneNumber.strip_non_digits_from_number(:contact_phone)
    |> validate_phi(:place)
  end

  def multi_for_insert(place_attrs, nil) do
    Multi.new()
    |> Multi.insert(:place, fn %{} ->
      %Place{} |> Cases.change_place(place_attrs)
    end)
  end

  def multi_for_insert(place_attrs, place_address_attrs) do
    multi_for_insert(place_attrs, nil)
    |> Multi.insert(:place_address, fn %{place: place} ->
      %PlaceAddress{place_id: place.id} |> Cases.change_place_address(place_address_attrs)
    end)
  end
end
