defmodule Epicenter.Accounts.Login do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Epicenter.Accounts.Login

  @required_attrs ~w{session_id user_agent user_id}a
  @optional_attrs ~w{tid}a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "logins" do
    field :seq, :integer, read_after_writes: true
    field :session_id, :binary_id
    field :tid, :string
    field :user_agent, :string
    field :user_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(login, attrs) do
    login
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  defmodule Query do
    import Ecto.Query

    def for_user_id(user_id) do
      from login in Login,
        where: login.user_id == ^user_id,
        order_by: [asc: login.inserted_at, asc: login.seq]
    end
  end
end
