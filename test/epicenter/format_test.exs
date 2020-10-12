defmodule Epicenter.FormatTest do
  use Epicenter.SimpleCase, async: true

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
end
