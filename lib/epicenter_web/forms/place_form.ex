defmodule EpicenterWeb.Forms.PlaceForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias EpicenterWeb.Forms.PlaceForm

  @primary_key false
  @required_attrs ~w{}a
  @optional_attrs ~w{name type}a
  embedded_schema do
    field :name, :string
    field :type, :string
  end

  def changeset(_place, attrs) do
    %PlaceForm{}
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def place_attrs(%Ecto.Changeset{} = changeset) do
    with {:ok, place_form} <- apply_action(changeset, :create) do
      {:ok, %{name: Map.get(place_form, :name), type: Map.get(place_form, :type)}}
    else
      other -> other
    end
  end
end
