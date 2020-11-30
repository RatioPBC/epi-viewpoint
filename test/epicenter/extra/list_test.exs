defmodule Epicenter.Extra.ListTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

  describe "concat" do
    test "concats two lists" do
      assert Extra.List.concat([1, 2], [3, 4]) == [1, 2, 3, 4]
    end

    test "works when the args aren't lists" do
      assert Extra.List.concat(1, [2, 3]) == [1, 2, 3]
      assert Extra.List.concat([1, 2], 3) == [1, 2, 3]
      assert Extra.List.concat(1, 2) == [1, 2]
    end
  end

  describe "sorted_flat_compact" do
    test "flattens the list, removes blank values, and sorts" do
      assert Extra.List.sorted_flat_compact(nil) == []
      assert Extra.List.sorted_flat_compact([]) == []
      assert Extra.List.sorted_flat_compact([1]) == [1]
      assert Extra.List.sorted_flat_compact([nil]) == []
      assert Extra.List.sorted_flat_compact([[[1, 5], 3, nil], "", [4, 2]]) == [1, 2, 3, 4, 5]
    end
  end
end
