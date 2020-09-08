defmodule Epicenter.Cases.Assignment do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Accounts.User
  alias Epicenter.Cases.Person

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "assignments" do
    field :seq, :integer
    field :tid, :string

    timestamps()

    belongs_to :person, Person
    belongs_to :user, User
  end

  @required_attrs ~w{person_id user_id}a
  @optional_attrs ~w{tid}a

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:person_id, name: :assignments_person_id_fkey)
    |> foreign_key_constraint(:user_id, name: :assignments_user_id_fkey)
  end
end
