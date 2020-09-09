defmodule Epicenter.Cases.Email do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  import Epicenter.Validation, only: [validate_phi: 2]

  alias Epicenter.Cases.Email

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "emails" do
    field :address, :string
    field :seq, :integer
    field :tid, :string
    field :person_id, :binary_id

    timestamps()
  end

  @required_attrs ~w{address person_id}a
  @optional_attrs ~w{tid}a

  @doc false
  def changeset(email, attrs) do
    email
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_phi(:email)
  end

  defmodule Query do
    def order_by_address(direction) do
      from(e in Email, order_by: [{^direction, :address}])
    end
  end
end
