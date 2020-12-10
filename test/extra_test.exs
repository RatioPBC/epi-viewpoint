defmodule Epicenter.ExtraTest do
  use ExUnit.Case, async: true

  describe "tap/2" do
    test "is a pipeline effect helper" do
      input = make_ref()
      assert Epicenter.Extra.tap(input, fn input -> send(self(), {:tap_called_me, input}) end) == input
      assert_received {:tap_called_me, ^input}
    end
  end
end
