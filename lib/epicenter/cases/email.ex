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
    field :delete, :boolean, virtual: true
    field :is_preferred, :boolean
    field :seq, :integer
    field :tid, :string
    field :person_id, :binary_id

    timestamps()
  end

  @required_attrs ~w{address person_id}a
  @optional_attrs ~w{delete is_preferred tid}a

  def changeset(email, attrs) do
    email
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_phi(:email)
    |> maybe_mark_for_deletion()
  end

  defp maybe_mark_for_deletion(%{data: %{id: nil}} = changeset),
    do: changeset

  defp maybe_mark_for_deletion(changeset),
    do: if(get_change(changeset, :delete), do: %{changeset | action: :delete}, else: changeset)

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
