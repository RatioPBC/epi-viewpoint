defmodule EpiViewpoint.Extra.MapTest do
  use EpiViewpoint.SimpleCase, async: false

  alias EpiViewpoint.Extra

  describe "delete_in" do
    test "removes the value at the keypath" do
      %{a: %{b: %{c: 1, d: 2}, e: 3}} |> Extra.Map.delete_in([:a, :b, :c]) |> assert_eq(%{a: %{b: %{d: 2}, e: 3}})
    end

    test "does nothing if there is nothing at the keypath" do
      %{a: %{b: 1}} |> Extra.Map.delete_in([:a, :b, :c]) |> assert_eq(%{a: %{b: 1}})
    end
  end

  describe "get_in" do
    test "gets the value at the keypath" do
      %{a: %{b: [1, 2]}} |> Extra.Map.get_in([:a, :b]) |> assert_eq([1, 2])
      %{"a" => %{"b" => [1, 2]}} |> Extra.Map.get_in(["a", "b"]) |> assert_eq([1, 2])
    end

    test "returns nil if there is nothing at the keypath" do
      %{a: %{b: [1, 2]}} |> Extra.Map.get_in([:a, :c]) |> assert_eq(nil)
      %{a: %{b: 1}} |> Extra.Map.get_in([:a, :b, :c]) |> assert_eq(nil)
    end
  end

  describe "put_in" do
    test "with :replace, if the new value is already in the map, does nothing" do
      %{a: %{b: 1}} |> Extra.Map.put_in([:a, :b], 1, on_conflict: :replace) |> assert_eq(%{a: %{b: 1}})
    end

    test "with :replace, if the keypath doesn't exist, the new value is added at the keypath" do
      %{} |> Extra.Map.put_in([:x, :y], 10, on_conflict: :replace) |> assert_eq(%{x: %{y: 10}})
      %{a: %{b: 1}} |> Extra.Map.put_in([:x, :y], 10, on_conflict: :replace) |> assert_eq(%{a: %{b: 1}, x: %{y: 10}})
    end

    test "with :replace, if a value exists at the keypath, it is replaced" do
      %{a: %{b: 1}} |> Extra.Map.put_in([:a, :b], 10, on_conflict: :replace) |> assert_eq(%{a: %{b: 10}})
      %{a: %{b: [1, 2]}} |> Extra.Map.put_in([:a, :b], 10, on_conflict: :replace) |> assert_eq(%{a: %{b: 10}})
    end

    test "with :list_append, if the existing value contains the new value, nothing is changed" do
      %{a: %{b: [1, 2]}} |> Extra.Map.put_in([:a, :b], 1, on_conflict: :list_append) |> assert_eq(%{a: %{b: [1, 2]}})
    end

    test "with :list_append, if the keypath exists, its value is replaced with a list containing the old value and the new value" do
      %{a: %{b: 1}} |> Extra.Map.put_in([:a, :b], 10, on_conflict: :list_append) |> assert_eq(%{a: %{b: [1, 10]}})
    end

    test "with :list_append, if the keypath exists and its value is a list, the new value is appended" do
      %{a: %{b: [1, 2]}} |> Extra.Map.put_in([:a, :b], 10, on_conflict: :list_append) |> assert_eq(%{a: %{b: [1, 2, 10]}})
    end
  end

  describe "has_key? with :coerce_key_to_existing_atom" do
    test "looks for the key when the map has a key of type atom, and the parameter is an atom" do
      map = %{key: "value"}
      assert Extra.Map.has_key?(map, :key, :coerce_key_to_existing_atom)
      refute Extra.Map.has_key?(map, :not_key, :coerce_key_to_existing_atom)
    end

    test "coerces to atom and looks for the key when the map has a key of type atom, and the parameter is a string" do
      map = %{key: "value"}
      assert Extra.Map.has_key?(map, "key", :coerce_key_to_existing_atom)
      refute Extra.Map.has_key?(map, "not_key", :coerce_key_to_existing_atom)
    end

    test "returns false when the map has key of type string, no matter the parameter type" do
      map = %{"key" => "value"}
      refute Extra.Map.has_key?(map, :key, :coerce_key_to_existing_atom)
      refute Extra.Map.has_key?(map, "key", :coerce_key_to_existing_atom)
    end
  end

  describe "to_list :depth_first" do
    test "converts a map of 'key -> value' or 'key -> values' into a list by alphabetizing keys and traversing depth-first" do
      %{"z" => "z1", "a" => "a1"} |> Extra.Map.to_list(:depth_first) |> assert_eq(["a", "a1", "z", "z1"])
      %{"z" => ["z1", "z2"], "a" => "a1"} |> Extra.Map.to_list(:depth_first) |> assert_eq(["a", "a1", "z", "z1", "z2"])
      %{"z" => ["z1", "z2"], "a" => ["a1", "a2"]} |> Extra.Map.to_list(:depth_first) |> assert_eq(["a", "a1", "a2", "z", "z1", "z2"])
    end
  end
end
