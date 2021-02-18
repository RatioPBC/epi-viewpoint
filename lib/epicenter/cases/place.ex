defmodule Epicenter.Cases.Place do
  use Ecto.Schema
  import Ecto.Changeset
  import Epicenter.PhiValidation, only: [validate_phi: 2]

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
  end

  def changeset(place, attrs) do
    place
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> Epicenter.PhoneNumber.strip_non_digits_from_number(:contact_phone)
    |> validate_phi(:place)
  end
end
