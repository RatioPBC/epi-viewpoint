defmodule EpiViewpoint.PhoneNumberTest do
  use EpiViewpoint.DataCase, async: true

  alias Ecto.Changeset
  alias EpiViewpoint.PhoneNumber

  defmodule TestSchema do
    use Ecto.Schema

    schema "test_schema" do
      field :phone_number, :string
    end
  end

  describe "stripping non-digits from phone number" do
    test "when there is no phone number, it does nothing" do
      changeset = Changeset.change(%TestSchema{}, %{})
      changeset = PhoneNumber.strip_non_digits_from_number(changeset, :phone_number)
      assert changeset.changes[:phone_number] == nil
    end

    test "when there is a phone number with non-digits, it strips the non-digits" do
      changeset = Changeset.change(%TestSchema{}, %{phone_number: "111-111-1111"})
      changeset = PhoneNumber.strip_non_digits_from_number(changeset, :phone_number)
      assert changeset.changes.phone_number == "1111111111"
    end

    test "when there is a phone number that's all digits, it does nothing" do
      changeset = Changeset.change(%TestSchema{}, %{phone_number: "1111111111"})
      changeset = PhoneNumber.strip_non_digits_from_number(changeset, :phone_number)
      assert changeset.changes.phone_number == "1111111111"
    end
  end
end
