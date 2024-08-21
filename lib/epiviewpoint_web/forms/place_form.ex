defmodule EpiViewpointWeb.Forms.PlaceForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias EpiViewpoint.PhiValidation
  alias EpiViewpointWeb.Forms.PlaceForm

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
    |> validate_name_or_address_present()
    |> EpiViewpoint.PhoneNumber.strip_non_digits_from_number(:contact_phone)
    |> PhiValidation.validate_phi(:place)
    |> PhiValidation.validate_phi(:address)
  end

  def place_attrs(%Ecto.Changeset{} = form_changeset) do
    with {:ok, place_form} <- apply_action(form_changeset, :create) do
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

  def validate_name_or_address_present(changeset) do
    if name_present?(changeset) or address_present?(changeset) do
      changeset
    else
      add_error(changeset, :name, "Name or address is required!")
    end
  end

  defp name_present?(changeset), do: get_field(changeset, :name) != nil

  defp address_present?(changeset) do
    address_fields = [:street, :city, :state, :postal_code]
    Enum.all?(address_fields, &get_field(changeset, &1))
  end
end
