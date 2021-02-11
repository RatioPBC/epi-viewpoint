defmodule Epicenter.Extra.EnumTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

  describe "equal_ignoring_order?" do
    test "returns true if the first enumerable is equal to the second, ignoring order" do
      assert Extra.Enum.equal_ignoring_order?(["c", "a", "d", "b"], ["a", "b", "c", "d"])
      refute Extra.Enum.equal_ignoring_order?(["c", "e", "d", "b"], ["a", "b", "c", "d"])
    end

    test "handles empty enumerables and nils" do
      refute Extra.Enum.equal_ignoring_order?(nil, ["a", "b"])
      assert Extra.Enum.equal_ignoring_order?(nil, nil)
      refute Extra.Enum.equal_ignoring_order?(["a", "b"], nil)
      assert Extra.Enum.equal_ignoring_order?([], [])
    end
  end

  describe "fetch_multiple" do
    test "fetches from multiple indices" do
      ~w{zero one two three four five}
      |> Extra.Enum.fetch_multiple([1, 3, 5])
      |> assert_eq(~w{one three five})
    end
  end

  describe "find_indices" do
    test "finds indices that equal the given values" do
      ~w{zero one two three four five}
      |> Extra.Enum.find_indices(~w{one three five})
      |> assert_eq([1, 3, 5])
    end
  end

  describe "intersect?" do
    test "returns true if the enums have any common elements" do
      assert Extra.Enum.intersect?(["a", "b", "c"], ["b", "d"])
      refute Extra.Enum.intersect?(["a", "b", "c"], ["d"])
    end

    test "handles empty enumerables and nils" do
      refute Extra.Enum.intersect?(nil, ["a", "b"])
      refute Extra.Enum.intersect?(nil, nil)
      refute Extra.Enum.intersect?(["a", "b"], nil)
      refute Extra.Enum.intersect?([], [])
    end
  end

  describe "reject_blank" do
    test "rejects blank values" do
      assert Extra.Enum.reject_blank(["a", "", "b", " ", "c", nil, "d"]) == ["a", "b", "c", "d"]
      assert Extra.Enum.reject_blank([]) == []
    end
  end

  describe "sort_uniq" do
    test "sorts and uniqifies, optionally taking a sort function" do
      assert Extra.Enum.sort_uniq([3, 2, 2, 3, 1]) == [1, 2, 3]
      assert Extra.Enum.sort_uniq([3, 2, 2, 3, 1], &(&1 >= &2)) == [3, 2, 1]
      assert Extra.Enum.sort_uniq([3, 2, 2, 3, 1], :desc) == [3, 2, 1]
    end
  end

  describe "subset?" do
    test "returns true if the first enumerable is a subset of the second, ignoring order" do
      assert Extra.Enum.subset?(["c", "a"], ["a", "b", "c", "d"])
      refute Extra.Enum.subset?(["c", "e"], ["a", "b", "c", "d"])
    end

    test "handles empty enumerables and nils" do
      refute Extra.Enum.subset?(nil, ["a", "b"])
      refute Extra.Enum.subset?(nil, nil)
      refute Extra.Enum.subset?(["a", "b"], nil)
      assert Extra.Enum.subset?([], [])
    end
  end
end
