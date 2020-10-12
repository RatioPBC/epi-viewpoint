defmodule Epicenter.FormatTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Cases.Phone

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
