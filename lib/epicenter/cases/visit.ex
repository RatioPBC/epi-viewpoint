defmodule Epicenter.Cases.Visit do
  use Ecto.Schema
  import Ecto.Changeset

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Place
  alias Epicenter.Cases.PlaceAddress
  alias Epicenter.Extra

  @required_attrs ~w{place_id case_investigation_id}a
  @optional_attrs ~w{tid relationship occurred_on}a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "visits" do
    field :occurred_on, :date
    field :relationship, :string
    field :seq, :integer, read_after_writes: true
    field :tid, :string

    belongs_to :case_investigation, CaseInvestigation
    belongs_to :place, Place

    timestamps(type: :utc_datetime)
  end

  def changeset(place, attrs) do
    place
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def to_comparable_string(%PlaceAddress{} = address) do
    [address.street, address.city, address.state, address.postal_code]
    |> Euclid.Extra.Enum.compact()
    |> Enum.map(fn s -> s |> Extra.String.squish() |> Extra.String.trim() |> String.downcase() end)
    |> Enum.join(" ")
  end
end
