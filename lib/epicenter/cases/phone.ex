defmodule Epicenter.Cases.Phone do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.Validation, only: [validate_phi: 2]

  alias Epicenter.Cases.Person

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "phones" do
    field :number, :integer
    field :seq, :integer
    field :tid, :string
    field :type, :string

    timestamps()

    belongs_to :person, Person
  end

  @required_attrs ~w{number person_id}a
  @optional_attrs ~w{tid type}a

  def changeset(phone, attrs) do
    phone
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_phi(:phone)
  end
end
