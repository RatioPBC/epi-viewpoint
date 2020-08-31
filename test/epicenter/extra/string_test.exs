defmodule Epicenter.Extra.StringTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

  describe "pluralize" do
    test "zero", do: assert(Extra.String.pluralize(0, "nerd", "nerds") == "0 nerds")
    test "one", do: assert(Extra.String.pluralize(1, "nerd", "nerds") == "1 nerd")
    test "many", do: assert(Extra.String.pluralize(2, "nerd", "nerds") == "2 nerds")
  end

  describe "squish" do
    test "removes whitespace" do
      assert " foo  BAR  \t baz \n FEz    " |> Extra.String.squish() == "foo BAR baz FEz"
    end

    test "allows nil" do
      nil |> Extra.String.squish() |> assert_eq(nil)
    end
  end

  describe "trim" do
    test "doesn't blow up on nil" do
      assert Extra.String.trim(nil) == nil
    end

    test "trims from left and right" do
      assert Extra.String.trim("  foo  ") == "foo"
    end
  end
end
