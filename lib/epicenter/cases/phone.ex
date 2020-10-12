defmodule Epicenter.Cases.Phone do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query
  import Epicenter.Validation, only: [validate_phi: 2]

  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Phone
  alias Epicenter.Extra

  @required_attrs ~w{number}a
  @optional_attrs ~w{delete is_preferred person_id tid type}a

  @derive {Jason.Encoder, only: @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "phones" do
    field :number, :string
    field :delete, :boolean, virtual: true
    field :is_preferred, :boolean
    field :seq, :integer
    field :tid, :string
    field :type, :string

    timestamps(type: :utc_datetime)

    belongs_to :person, Person
  end

  def changeset(phone, attrs) do
    phone
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> strip_non_digits_from_number()
    |> validate_required(@required_attrs)
    |> validate_phi(:phone)
    |> unique_constraint([:person_id, :number], name: :phone_number_person_id_index)
    |> Extra.Changeset.maybe_mark_for_deletion()
  end

  defp strip_non_digits_from_number(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.fetch_field(:number)
    |> elem(1)
    |> case do
      nil -> changeset
      number -> Ecto.Changeset.put_change(changeset, :number, strip_non_digits_from_number(number))
    end
  end

  defp strip_non_digits_from_number(number) when is_binary(number) do
    number
    |> String.graphemes()
    |> Enum.filter(fn element -> element =~ ~r{\d} end)
    |> Enum.join()
  end

  defmodule Query do
    def all() do
      from phone in Phone, order_by: [asc: phone.number, asc: phone.seq]
    end

    def display_order() do
      from phone in Phone,
        order_by: [fragment("case when is_preferred=true then 0 else 1 end"), asc_nulls_last: :number]
    end

    def order_by_number(direction) do
      from(e in Phone, order_by: [{^direction, :number}])
    end

    def opts_for_upsert() do
      [returning: true, on_conflict: {:replace, ~w{updated_at}a}, conflict_target: [:person_id, :number]]
    end
  end
end
