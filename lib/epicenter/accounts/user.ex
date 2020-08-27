defmodule Epicenter.Accounts.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Accounts.User

  @derive {Jason.Encoder, only: [:id]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :seq, :integer
    field :tid, :string
    field :username, :string

    timestamps()
  end

  @required_attrs ~w{username}a
  @optional_attrs ~w{tid}a

  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:username)
  end

  defmodule Query do
    import Ecto.Query

    def all() do
      from user in User, order_by: [asc: user.username, asc: user.seq]
    end
  end
end