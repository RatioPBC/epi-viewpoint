defmodule EpicenterWeb.Forms.PlaceForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias EpicenterWeb.Forms.PlaceForm

  @primary_key false
  @required_attrs ~w{}a
  @optional_attrs ~w{name street street_2 city state postal_code type contact_name contact_phone contact_email}a
  embedded_schema do
    field :name, :string
    field :street, :string
    field :street_2, :string
    field :city, :string
    field :state, :string
    field :postal_code, :string
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
        street: Map.get(place_form, :street),
        street_2: Map.get(place_form, :street_2),
        city: Map.get(place_form, :city),
        state: Map.get(place_form, :state),
        postal_code: Map.get(place_form, :postal_code)
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
end
