defmodule Epicenter.Cases.Visit do
  use Ecto.Schema
  import Ecto.Changeset

  alias Epicenter.Cases.Place
  alias Epicenter.Cases.PlaceAddress
  alias Epicenter.Extra

  @required_attrs ~w{place_id}a
  @optional_attrs ~w{tid}a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "visits" do
    field :occurred_on, :date
    field :seq, :integer, read_after_writes: true
    field :tid, :string

    belongs_to :place, Place
    # todo: should belong to a CaseInvestigation or a Person, depending on outcome of some decision
    # belongs_to :case_investigation, CaseInvestigation

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
