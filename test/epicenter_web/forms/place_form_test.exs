defmodule EpicenterWeb.Forms.PlaceFormTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases.Place
  alias EpicenterWeb.Forms.PlaceForm

  @place_attrs %{
    contact_email: "alice@example.com",
    contact_name: "Alice Testuser",
    contact_phone: "111-111-1234",
    name: "123 Elementary",
    type: "school"
  }

  @place_address_attrs %{
    street: "1234 Test St"
  }

  describe "creating changeset and retrieving attrs" do
    test "when there are only place attrs" do
      changeset = PlaceForm.changeset(%Place{}, @place_attrs)
      assert PlaceForm.place_attrs(changeset) == {:ok, @place_attrs}
      assert PlaceForm.place_address_attrs(changeset) == {:ok, nil}
    end

    test "when there are place and address attrs" do
      changeset = PlaceForm.changeset(%Place{}, @place_attrs |> Map.merge(@place_address_attrs))
      assert PlaceForm.place_attrs(changeset) == {:ok, @place_attrs}
      assert PlaceForm.place_address_attrs(changeset) == {:ok, @place_address_attrs}
    end
  end
end
