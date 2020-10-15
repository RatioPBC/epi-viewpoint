defmodule Epicenter.ValidationTest do
  use Epicenter.DataCase, async: true

  alias Ecto.Changeset
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Phone
  alias Epicenter.Cases.Email
  alias Epicenter.Validation

  describe "validate_phi: person last_name" do
    @valid_last_name "Testuser2"
    @invalid_last_name "Baz"

    test "changeset is valid if last_name starts with 'Testuser'" do
      Changeset.change(%Person{}, last_name: @valid_last_name)
      |> Validation.validate_phi(:person)
      |> assert_valid()
    end

    test "changeset is invalid if last_name does not start with 'Testuser'" do
      Changeset.change(%Person{}, last_name: @invalid_last_name)
      |> Validation.validate_phi(:person)
      |> assert_invalid(last_name: ["In non-PHI environment, must start with 'Testuser'"])
    end

    test "changeset is valid when there are no user input restrictions" do
      Changeset.change(%Person{}, last_name: @invalid_last_name)
      |> Validation.validate_phi(:person, :unrestricted)
      |> assert_valid()
    end
  end

  describe "validate_phi: person dob" do
    @valid_dob ~D[2020-01-01]
    @invalid_dob ~D[2020-01-02]

    test "changeset is valid if date of birth is first of month" do
      Changeset.change(%Person{}, dob: @valid_dob)
      |> Validation.validate_phi(:person)
      |> assert_valid()
    end

    test "changeset is invalid if date of birth is not first of month" do
      Changeset.change(%Person{}, dob: @invalid_dob)
      |> Validation.validate_phi(:person)
      |> assert_invalid(dob: ["In non-PHI environment, must be the first of the month"])
    end

    test "changeset is valid when there are no user input restrictions" do
      Changeset.change(%Person{}, dob: @invalid_dob)
      |> Validation.validate_phi(:person, :unrestricted)
      |> assert_valid()
    end
  end

  describe "validate_phi: phone number" do
    @valid_phone_number "1111111567"
    @invalid_phone_number "12345"

    test "changest is valid if phone number matches '111-111-1xxx'" do
      Changeset.change(%Phone{}, number: @valid_phone_number)
      |> Validation.validate_phi(:phone)
      |> assert_valid()
    end

    test "changest is invalid if phone number does not match '111-111-1xxx'" do
      Changeset.change(%Phone{}, number: @invalid_phone_number)
      |> Validation.validate_phi(:phone)
      |> assert_invalid(number: ["In non-PHI environment, must match '111-111-1xxx'"])
    end

    test "changest is valid when there are no user input restrictions" do
      Changeset.change(%Phone{}, number: @invalid_phone_number)
      |> Validation.validate_phi(:phone, :unrestricted)
      |> assert_valid()
    end
  end

  describe "validate_phi: email address" do
    @valid_email_address "test@example.com"
    @invalid_email_address "test@google.com"

    test "changeset is valid if email address ends with '@example.com'" do
      Changeset.change(%Email{}, address: @valid_email_address)
      |> Validation.validate_phi(:email)
      |> assert_valid()
    end

    test "changeset is invalid if email address does not end with '@example.com'" do
      Changeset.change(%Email{}, address: @invalid_email_address)
      |> Validation.validate_phi(:email)
      |> assert_invalid(address: ["In non-PHI environment, must end with '@example.com'"])
    end

    test "changeset is valid when there are no user input restrictions" do
      Changeset.change(%Email{}, address: @invalid_email_address)
      |> Validation.validate_phi(:email, :unrestricted)
      |> assert_valid()
    end
  end

  describe "validate_phi: street" do
    @valid_street "1234 Test St"
    @invalid_street "44 Main St"

    test "changeset is valid if street is on Test St" do
      Changeset.change(%Address{}, street: @valid_street)
      |> Validation.validate_phi(:address)
      |> assert_valid()
    end

    test "changeset is invalid if street is not on Test St" do
      Changeset.change(%Address{}, street: @invalid_street)
      |> Validation.validate_phi(:address)
      |> assert_invalid(street: ["In non-PHI environment, must match '#### Test St'"])
    end

    test "changeset is valid when there are no user input restrictions" do
      Changeset.change(%Address{}, street: @invalid_street)
      |> Validation.validate_phi(:address, :unrestricted)
      |> assert_valid()
    end
  end

  describe "validate_phi: city" do
    @valid_city "City3"
    @invalid_city "Real City"

    test "changeset is valid if city is City followed by an optional number" do
      Changeset.change(%Address{}, city: @valid_city)
      |> Validation.validate_phi(:address)
      |> assert_valid()
    end

    test "changeset is invalid if city does not start with City and end in a number" do
      Changeset.change(%Address{}, city: @invalid_city)
      |> Validation.validate_phi(:address)
      |> assert_invalid(city: ["In non-PHI environment, must match 'City#'"])
    end

    test "changeset is valid when there are no user input restrictions" do
      Changeset.change(%Address{}, city: @invalid_city)
      |> Validation.validate_phi(:address, :unrestricted)
      |> assert_valid()
    end
  end

  describe "validate_phi: state" do
    @valid_state "ZA"
    @invalid_state "AA"

    test "changeset is valid if state is TS or starts with Z" do
      Changeset.change(%Address{}, state: "TS")
      |> Validation.validate_phi(:address)
      |> assert_valid()

      Changeset.change(%Address{}, state: @valid_state)
      |> Validation.validate_phi(:address)
      |> assert_valid()
    end

    test "changeset is invalid if state is TS and doesn't start with Z" do
      Changeset.change(%Address{}, state: @invalid_state)
      |> Validation.validate_phi(:address)
      |> assert_invalid(state: ["In non-PHI environment, must be TS or end with Z"])
    end

    test "changeset is valid when there are no user input restrictions" do
      Changeset.change(%Address{}, state: @invalid_state)
      |> Validation.validate_phi(:address, :unrestricted)
      |> assert_valid()
    end
  end

  describe "validate_phi: postal code" do
    @valid_postal_code "00002"
    @invalid_postal_code "33333"

    test "changeset is valid if postal_code starts with 4 zeros" do
      Changeset.change(%Address{}, postal_code: @valid_postal_code)
      |> Validation.validate_phi(:address)
      |> assert_valid()
    end

    test "changeset is invalid if postal_code does not start with 4 zeros" do
      Changeset.change(%Address{}, postal_code: @invalid_postal_code)
      |> Validation.validate_phi(:address)
      |> assert_invalid(postal_code: ["In non-PHI environment, must match '0000x'"])
    end

    test "changeset is valid when there are no user input restrictions" do
      Changeset.change(%Address{}, postal_code: @invalid_postal_code)
      |> Validation.validate_phi(:address, :unrestricted)
      |> assert_valid()
    end
  end
end
