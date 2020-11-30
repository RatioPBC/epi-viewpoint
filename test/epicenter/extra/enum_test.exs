defmodule Epicenter.Extra.EnumTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

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

  describe "reject_blank" do
    test "rejects blank values" do
      assert Extra.Enum.reject_blank(["a", "", "b", " ", "c", nil, "d"]) == ["a", "b", "c", "d"]
      assert Extra.Enum.reject_blank([]) == []
    end
  end
end
