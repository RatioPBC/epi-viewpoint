defmodule EpicenterWeb.Forms.AddVisitForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias EpicenterWeb.Forms.AddVisitForm

  @primary_key false
  @required_attrs ~w{}a
  @optional_attrs ~w{}a
  embedded_schema do
    field :occurred_on, :date
    field :relationship, :string
  end

  def changeset(_place, attrs) do
    %AddVisitForm{}
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  # def place_attrs(%Ecto.Changeset{} = changeset) do
  #   with {:ok, place_form} <- apply_action(changeset, :create) do
  #     {:ok,
  #      %{
  #        city: Map.get(place_form, :city),
  #        postal_code: Map.get(place_form, :postal_code),
  #        state: Map.get(place_form, :state),
  #        street: Map.get(place_form, :street)
  #      }}
  #   else
  #     other -> other
  #   end
  # end
end
