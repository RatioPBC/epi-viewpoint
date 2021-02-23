defmodule EpicenterWeb.Forms.PlaceForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias EpicenterWeb.Forms.PlaceForm

  @primary_key false
  @required_attrs ~w{}a
  @optional_attrs ~w{name street type contact_name contact_phone contact_email}a
  embedded_schema do
    field :name, :string
    field :street, :string
    field :type, :string
    field :contact_name, :string
    field :contact_phone, :string
    field :contact_email, :string
  end

  def changeset(_place, attrs) do
    %PlaceForm{}
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def place_attrs(%Ecto.Changeset{} = changeset) do
    with {:ok, place_form} <- apply_action(changeset, :create) do
      attrs = %{
        name: Map.get(place_form, :name),
        type: Map.get(place_form, :type),
        contact_name: Map.get(place_form, :contact_name),
        contact_phone: Map.get(place_form, :contact_phone),
        contact_email: Map.get(place_form, :contact_email)
      }

      address_attrs = %{
        street: Map.get(place_form, :street)
      }

      attrs =
        if Euclid.Extra.Map.all_values_blank?(address_attrs),
          do: attrs,
          else: attrs |> Map.put(:place_addresses, [address_attrs])

      {:ok, attrs}
    else
      other -> other
    end
  end

  def place_address_attrs(%Ecto.Changeset{} = changeset) do
    with {:ok, place_form} <- apply_action(changeset, :create) do
      attrs = %{
        street: Map.get(place_form, :street)
      }

      case Euclid.Extra.Map.all_values_blank?(attrs) do
        true -> {:ok, nil}
        false -> {:ok, attrs}
      end
    else
      other -> other
    end
  end
end
