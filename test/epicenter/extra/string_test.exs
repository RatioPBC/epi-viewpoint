defmodule Epicenter.Extra.StringTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

  describe "pluralize" do
    test "zero", do: assert(Extra.String.pluralize(0, "nerd", "nerds") == "0 nerds")
    test "one", do: assert(Extra.String.pluralize(1, "nerd", "nerds") == "1 nerd")
    test "many", do: assert(Extra.String.pluralize(2, "nerd", "nerds") == "2 nerds")
  end

  describe "remove_non_numbers" do
    test "doesn't blow up on nil" do
      assert Extra.String.remove_non_numbers(nil) == nil
    end

    test "removes things that aren't numbers" do
      assert " a 1 - b2/34  5?6" |> Extra.String.remove_non_numbers() == "123456"
    end
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
