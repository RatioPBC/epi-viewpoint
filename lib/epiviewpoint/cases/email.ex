defmodule EpiViewpoint.Cases.Email do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  import EpiViewpoint.PhiValidation, only: [validate_phi: 2]

  alias EpiViewpoint.Cases.Email
  alias EpiViewpoint.Extra

  @required_attrs ~w{address}a
  @optional_attrs ~w{delete is_preferred person_id tid}a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "emails" do
    field :address, :string
    field :delete, :boolean, virtual: true
    field :is_preferred, :boolean
    field :seq, :integer, read_after_writes: true
    field :source, :string
    field :tid, :string
    field :person_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(email, attrs) do
    email
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_phi(:email)
    |> Extra.Changeset.maybe_mark_for_deletion()
  end

  defmodule Query do
    def display_order() do
      from email in Email,
        order_by: [fragment("case when is_preferred=true then 0 else 1 end"), asc_nulls_last: :address]
    end

    def order_by_address(direction) do
      from(e in Email, order_by: [{^direction, :address}])
    end
  end
end
