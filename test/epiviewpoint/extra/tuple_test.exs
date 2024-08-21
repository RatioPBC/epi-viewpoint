defmodule EpiViewpoint.Extra.TupleTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpoint.Extra

  describe "append" do
    test "appends when the first argument is a tuple" do
      assert Extra.Tuple.append({1, 2}, 3) == {1, 2, 3}
    end

    test "creates and appends when the first argument is not a tuple" do
      assert Extra.Tuple.append(1, 2) == {1, 2}
    end
  end
end
