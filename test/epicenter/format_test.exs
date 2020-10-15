defmodule Epicenter.FormatTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Cases.Address
  alias Epicenter.Cases.Phone

  describe "address" do
    import Epicenter.Format, only: [address: 1]

    test "returns an empty string when the address is nil" do
      assert address(nil) == ""
    end

    test "returns a correctly formatted address when all fields are present" do
      full_address = %Address{street: "1001 Test St", city: "City", state: "TS", postal_code: "00000"}

      assert address(full_address) == "1001 Test St, City, TS 00000"
    end

    test "returns a correctly formatted address when postal code is missing " do
      full_address = %Address{street: "1001 Test St", city: "City", state: "TS", postal_code: nil}

      assert address(full_address) == "1001 Test St, City, TS"
    end

    test "returns a correctly formatted address when all fields state is missing" do
      full_address = %Address{street: "1001 Test St", city: "City", state: nil, postal_code: "00000"}

      assert address(full_address) == "1001 Test St, City 00000"
    end

    test "returns a correctly formatted address when all fields state and city is missing" do
      full_address = %Address{street: "1001 Test St", city: nil, state: nil, postal_code: "00000"}

      assert address(full_address) == "1001 Test St 00000"
    end

    test "returns a correctly formatted address when only street is present" do
      full_address = %Address{street: "1001 Test St", city: nil, state: nil, postal_code: nil}

      assert address(full_address) == "1001 Test St"
    end
  end

  describe "date" do
    import Epicenter.Format, only: [date: 1]

    test "when given a date, formats it as mm/dd/yyyy" do
      assert date(~D[2020-05-19]) == "05/19/2020"
    end

    test "when given a nil, quietly renders an empty string" do
      assert date(nil) == ""
    end
  end

  describe "person" do
    import Epicenter.Format, only: [person: 1]

    test "formats structs that have first and last name" do
      assert person(%{first_name: "Alice", last_name: "Ant"}) == "Alice Ant"
      assert person(%{first_name: nil, last_name: "Ant"}) == "Ant"
      assert person(%{first_name: "Alice", last_name: nil}) == "Alice"
      assert person(%{first_name: nil, last_name: nil}) == ""
      assert person(nil) == ""
    end
  end

  describe "phone" do
    import Epicenter.Format, only: [phone: 1]

    test "formats phone number strings when they only contain numbers" do
      assert phone("911") == "911"
      assert phone("4155551212") == "(415) 555-1212"
      assert phone("14155551212") == "+1 (415) 555-1212"
      assert phone(nil) == ""
    end

    test "doesn't do anything with strings that contain more than numbers" do
      assert phone("555.1212") == "555.1212"
      assert phone("415 555 1212") == "415 555 1212"
      assert phone("1 415 555 1212") == "1 415 555 1212"
      assert phone("+1 415 555 1212") == "+1 415 555 1212"
      assert phone("glorp") == "glorp"
    end

    test "formats Phone numbers" do
      assert phone(%Phone{number: "911"}) == "911"
      assert phone(%Phone{number: "4155551212"}) == "(415) 555-1212"
      assert phone(%Phone{number: nil}) == ""
    end
  end
end
