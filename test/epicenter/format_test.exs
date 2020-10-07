defmodule Epicenter.FormatTest do
  use Epicenter.SimpleCase, async: true

  import Epicenter.Format, only: [format: 1]

  test "formats structs that have first and last name" do
    assert format(%{first_name: "Alice", last_name: "Ant"}) == "Alice Ant"
    assert format(%{first_name: nil, last_name: "Ant"}) == "Ant"
    assert format(%{first_name: "Alice", last_name: nil}) == "Alice"
    assert format(%{first_name: nil, last_name: nil}) == ""
  end
end
