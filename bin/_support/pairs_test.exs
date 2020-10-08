ExUnit.start()

defmodule PairsTest do
  use ExUnit.Case

  describe "validate" do
    import Pairs, only: [validate: 1]

    test "returns :duplicates if there are dupes" do
      assert validate([~w{a b}, ~w{b c}]) == :duplicates
    end

    test "returns the input if there are no dupes" do
      assert validate([~w{a b}, ~w{c d}]) == [~w{a b}, ~w{c d}]
    end
  end

  describe "reduce_pairs" do
    import Pairs, only: [reduce_pairs: 3]

    test "with empty lists, returns nothing" do
      assert reduce_pairs(~w{}, ~w{}, ~w{}) == []
    end

    test "pairs the first items of each list" do
      assert reduce_pairs(~w{a1 a2 a3}, ~w{b1 b2 b3}, ~w{}) == ["a3 + b3", "a2 + b2", "a1 + b1"]
    end

    test "if there are more sticky than nonsticky, some stickies solo" do
      assert reduce_pairs(~w{a1 a2 a3}, ~w{b1 b2}, ~w{}) == ["a3 solos", "a2 + b2", "a1 + b1"]
    end

    test "if there are more nonsticky than nsticky, some nonstickies solo" do
      assert reduce_pairs(~w{a1 a2}, ~w{b1 b2 b3}, ~w{}) == ["b3 solos", "a2 + b2", "a1 + b1"]
    end

    test "if everyone is sticky, nobody pairs" do
      assert reduce_pairs(~w{a1 a2 a3}, ~w{}, ~w{}) == ["a3 solos", "a2 solos", "a1 solos"]
    end

    test "if nobody is sticky, everybody pairs" do
      assert reduce_pairs(~w{}, ~w{b1 b2 b3 b4}, ~w{}) == ["b3 + b4", "b1 + b2"]
    end

    test "if nobody is sticky, everybody pairs unless there's an odd number" do
      assert reduce_pairs(~w{}, ~w{b1 b2 b3}, ~w{}) == ["b3 solos", "b1 + b2"]
    end
  end
end
