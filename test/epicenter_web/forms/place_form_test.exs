defmodule EpicenterWeb.Forms.PlaceFormTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases.Place
  alias EpicenterWeb.Forms.PlaceForm

  describe "creating changeset and retrieving attrs" do
    test "when there are only place attrs" do
      changeset =
        PlaceForm.changeset(%Place{}, %{
          contact_email: "alice@example.com",
          contact_name: "Alice Testuser",
          contact_phone: "111-111-1234",
          name: "123 Elementary",
          type: "school"
        })

      assert PlaceForm.place_attrs(changeset) ==
               {:ok,
                %{
                  contact_email: "alice@example.com",
                  contact_name: "Alice Testuser",
                  contact_phone: "111-111-1234",
                  name: "123 Elementary",
                  type: "school"
                }}
    end

    test "when there are place and address attrs" do
      changeset =
        PlaceForm.changeset(%Place{}, %{
          contact_email: "alice@example.com",
          contact_name: "Alice Testuser",
          contact_phone: "111-111-1234",
          name: "123 Elementary",
          type: "school",
          street: "1234 Test St",
          street_2: "Apt. 202",
          city: "City",
          state: "OH",
          postal_code: "00000"
        })

      assert PlaceForm.place_attrs(changeset) ==
               {:ok,
                %{
                  contact_email: "alice@example.com",
                  contact_name: "Alice Testuser",
                  contact_phone: "111-111-1234",
                  name: "123 Elementary",
                  type: "school",
                  place_addresses: [
                    %{
                      street: "1234 Test St",
                      street_2: "Apt. 202",
                      city: "City",
                      state: "OH",
                      postal_code: "00000"
                    }
                  ]
                }}
    end
  end
end
