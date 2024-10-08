defmodule EpiViewpoint.Cases.Visit do
  use Ecto.Schema
  import Ecto.Changeset

  alias EpiViewpoint.Cases.CaseInvestigation
  alias EpiViewpoint.Cases.Place
  alias EpiViewpoint.Cases.PlaceAddress
  alias EpiViewpoint.Extra

  @required_attrs ~w{place_id case_investigation_id}a
  @optional_attrs ~w{deleted_at tid relationship occurred_on}a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "visits" do
    field :deleted_at, :utc_datetime
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

  defmodule Query do
    import Ecto.Query

    alias EpiViewpoint.Cases.Visit

    def display_order() do
      from visit in Visit,
        where: is_nil(visit.deleted_at),
        order_by: [asc: visit.seq]
    end
  end
end
