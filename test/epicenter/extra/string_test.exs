defmodule Epicenter.Extra.StringTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

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
