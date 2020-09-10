defmodule Epicenter.Cases.Phone do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query
  import Epicenter.Validation, only: [validate_phi: 2]

  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Phone

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "phones" do
    field :number, :integer
    field :is_preferred, :boolean
    field :seq, :integer
    field :tid, :string
    field :type, :string

    timestamps()

    belongs_to :person, Person
  end

  @required_attrs ~w{number person_id}a
  @optional_attrs ~w{is_preferred tid type}a

  def changeset(phone, attrs) do
    phone
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_phi(:phone)
  end

  defmodule Query do
    def display_order() do
      from phone in Phone,
        order_by: [fragment("case when is_preferred=true then 0 else 1 end"), asc_nulls_last: :number]
    end

    def order_by_number(direction) do
      from(e in Phone, order_by: [{^direction, :number}])
    end
  end
end
