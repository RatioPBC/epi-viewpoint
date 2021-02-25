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
                  contact_phone: "1111111234",
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
                  contact_phone: "1111111234",
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

    test "validates" do
      valid_attrs = %{
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
      }

      assert_valid(PlaceForm.changeset(nil, valid_attrs))
      assert_invalid(PlaceForm.changeset(nil, %{valid_attrs | contact_email: "unsafe@google.com"}))
      assert_invalid(PlaceForm.changeset(nil, %{valid_attrs | contact_name: "Unsafe name"}))
      assert_invalid(PlaceForm.changeset(nil, %{valid_attrs | contact_phone: "123-456-7890"}))
      assert_invalid(PlaceForm.changeset(nil, %{valid_attrs | street: "Unsafe street"}))
      assert_invalid(PlaceForm.changeset(nil, %{valid_attrs | street: "Unsafe city"}))
      assert_invalid(PlaceForm.changeset(nil, %{valid_attrs | street: "Unsafe postal code"}))
    end
  end

  test "requires either name or address" do
    name_only_attrs = %{
      name: "123 Elementary"
    }

    address_only_attrs = %{
      street: "1234 Test St",
      street_2: "Apt. 202",
      city: "City",
      state: "OH",
      postal_code: "00000"
    }

    partial_address_only_attrs = %{
      street: "1234 Test St",
      postal_code: "00000"
    }

    empty_attrs = %{}

    assert_valid(PlaceForm.changeset(nil, name_only_attrs))
    assert_valid(PlaceForm.changeset(nil, address_only_attrs))
    assert_invalid(PlaceForm.changeset(nil, partial_address_only_attrs))
    assert_invalid(PlaceForm.changeset(nil, empty_attrs))
  end
end
