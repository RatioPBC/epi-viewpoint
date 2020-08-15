defmodule Epicenter.Cases.Person do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Cases.Person

  schema "people" do
    field :dob, :date
    field :first_name, :string
    field :last_name, :string
    field :tid, :string

    timestamps()
  end

  @required_attrs ~w{dob first_name last_name}a
  @optional_attrs ~w{tid}a

  def changeset(person, attrs) do
    person
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  defmodule Query do
    import Ecto.Query

    def all() do
      from person in Person, order_by: [asc: person.last_name, asc: person.first_name, desc: person.dob, asc: person.id]
    end
  end
end
