defmodule Epicenter.CoerceTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Coerce

  describe "to_string_or_nil" do
    test "coerces nil and empty list to nil" do
      assert Coerce.to_string_or_nil(nil) == nil
      assert Coerce.to_string_or_nil([]) == nil
      assert Coerce.to_string_or_nil([nil]) == nil
    end

    test "coerces string or one-item string list to a string" do
      assert Coerce.to_string_or_nil("string") == "string"
      assert Coerce.to_string_or_nil(["string"]) == "string"
    end

    test "won't coerce other things" do
      assert_raise RuntimeError, "Expected nil, a string, or a list with one string, got: 4", fn ->
        Coerce.to_string_or_nil(4)
      end

      assert_raise RuntimeError, "Expected nil, a string, or a list with one string, got: [4]", fn ->
        Coerce.to_string_or_nil([4])
      end

      assert_raise RuntimeError, ~s|Expected nil, a string, or a list with one string, got: ["s1", "s2"]|, fn ->
        Coerce.to_string_or_nil(["s1", "s2"])
      end
    end
  end
end
