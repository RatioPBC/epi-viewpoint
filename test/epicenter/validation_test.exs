defmodule Epicenter.ValidationTest do
  use Epicenter.DataCase, async: true

  alias Ecto.Changeset
  alias Epicenter.Cases.Person
  alias Epicenter.Validation

  describe "validate_phi" do
    test "changeset in invalid if last_name is not 'Testuser'" do
      change = Changeset.change(%Person{}, last_name: "Baz")
      assert errors_on(Validation.validate_phi(change)).last_name == ["In non-PHI environment, must be equal to 'Testuser'"]
    end

    test "changeset in invalid if date of birth is not first of month" do
      change = Changeset.change(%Person{}, dob: ~D[2020-01-02])
      assert errors_on(Validation.validate_phi(change)).dob == ["In non-PHI environment, must be the first of the month"]
    end
  end
end
