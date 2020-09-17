defmodule Epicenter.ValidationTest do
  use Epicenter.DataCase, async: true

  alias Ecto.Changeset
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Phone
  alias Epicenter.Cases.Email
  alias Epicenter.Validation

  describe "validate_phi" do
    test "changeset in invalid if last_name does not start with 'Testuser'" do
      change = Changeset.change(%Person{}, last_name: "Baz")
      assert errors_on(Validation.validate_phi(change, :person)).last_name == ["In non-PHI environment, must start with 'Testuser'"]

      change = Changeset.change(%Person{}, last_name: "Testuser2")
      assert Validation.validate_phi(change, :person).valid?
    end

    test "changeset in invalid if date of birth is not first of month" do
      change = Changeset.change(%Person{}, dob: ~D[2020-01-02])
      assert errors_on(Validation.validate_phi(change, :person)).dob == ["In non-PHI environment, must be the first of the month"]
    end

    test "changest is invalid if phone number does not match '111-111-1xxx'" do
      change = Changeset.change(%Phone{}, number: 12345)
      assert errors_on(Validation.validate_phi(change, :phone)).number == ["In non-PHI environment, must match '111-111-1xxx'"]
    end

    test "changeset is invalid if email address does not end with '@example.com'" do
      change = Changeset.change(%Email{}, address: "test@google.com")
      assert errors_on(Validation.validate_phi(change, :email)).address == ["In non-PHI environment, must end with '@example.com'"]
    end
  end
end
