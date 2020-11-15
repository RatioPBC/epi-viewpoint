defmodule Epicenter.Extra.MapTest do
  use Epicenter.SimpleCase, async: false

  alias Epicenter.Extra

  describe "to_list :depth_first" do
    test "converts a map of 'key -> value' or 'key -> values' into a list by alphabetizing keys and traversing depth-first" do
      %{"z" => "z1", "a" => "a1"} |> Extra.Map.to_list(:depth_first) |> assert_eq(["a", "a1", "z", "z1"])
      %{"z" => ["z1", "z2"], "a" => "a1"} |> Extra.Map.to_list(:depth_first) |> assert_eq(["a", "a1", "z", "z1", "z2"])
      %{"z" => ["z1", "z2"], "a" => ["a1", "a2"]} |> Extra.Map.to_list(:depth_first) |> assert_eq(["a", "a1", "a2", "z", "z1", "z2"])
    end
  end
end
