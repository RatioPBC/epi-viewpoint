defmodule Epicenter.Extra.MapTest do
  use Epicenter.SimpleCase, async: false

  alias Epicenter.Extra

  describe "delete_in" do
    test "removes the value at the keypath" do
      %{a: %{b: %{c: 1, d: 2}, e: 3}} |> Extra.Map.delete_in([:a, :b, :c]) |> assert_eq(%{a: %{b: %{d: 2}, e: 3}}, :simple)
    end

    test "does nothing if there is nothing at the keypath" do
      %{a: %{b: 1}} |> Extra.Map.delete_in([:a, :b, :c]) |> assert_eq(%{a: %{b: 1}}, :simple)
    end
  end

  describe "get_in" do
    test "gets the value at the keypath" do
      %{a: %{b: [1, 2]}} |> Extra.Map.get_in([:a, :b]) |> assert_eq([1, 2], :simple)
      %{"a" => %{"b" => [1, 2]}} |> Extra.Map.get_in(["a", "b"]) |> assert_eq([1, 2], :simple)
    end

    test "returns nil if there is nothing at the keypath" do
      %{a: %{b: [1, 2]}} |> Extra.Map.get_in([:a, :c]) |> assert_eq(nil)
      %{a: %{b: 1}} |> Extra.Map.get_in([:a, :b, :c]) |> assert_eq(nil)
    end
  end

  describe "put_in" do
    test "with :replace, if the new value is already in the map, does nothing" do
      %{a: %{b: 1}} |> Extra.Map.put_in([:a, :b], 1, on_conflict: :replace) |> assert_eq(%{a: %{b: 1}}, :simple)
    end

    test "with :replace, if the keypath doesn't exist, the new value is added at the keypath" do
      %{} |> Extra.Map.put_in([:x, :y], 10, on_conflict: :replace) |> assert_eq(%{x: %{y: 10}}, :simple)
      %{a: %{b: 1}} |> Extra.Map.put_in([:x, :y], 10, on_conflict: :replace) |> assert_eq(%{a: %{b: 1}, x: %{y: 10}}, :simple)
    end

    test "with :replace, if a value exists at the keypath, it is replaced" do
      %{a: %{b: 1}} |> Extra.Map.put_in([:a, :b], 10, on_conflict: :replace) |> assert_eq(%{a: %{b: 10}}, :simple)
      %{a: %{b: [1, 2]}} |> Extra.Map.put_in([:a, :b], 10, on_conflict: :replace) |> assert_eq(%{a: %{b: 10}}, :simple)
    end

    test "with :list_append, if the existing value contains the new value, nothing is changed" do
      %{a: %{b: [1, 2]}} |> Extra.Map.put_in([:a, :b], 1, on_conflict: :list_append) |> assert_eq(%{a: %{b: [1, 2]}}, :simple)
    end

    test "with :list_append, if the keypath exists, its value is replaced with a list containing the old value and the new value" do
      %{a: %{b: 1}} |> Extra.Map.put_in([:a, :b], 10, on_conflict: :list_append) |> assert_eq(%{a: %{b: [1, 10]}}, :simple)
    end

    test "with :list_append, if the keypath exists and its value is a list, the new value is appended" do
      %{a: %{b: [1, 2]}} |> Extra.Map.put_in([:a, :b], 10, on_conflict: :list_append) |> assert_eq(%{a: %{b: [1, 2, 10]}}, :simple)
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
