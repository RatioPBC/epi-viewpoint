defmodule Epicenter.ExtraTest do
  use ExUnit.Case, async: true

  describe "tap/2" do
    test "is a pipeline effect helper" do
      input = make_ref()
      assert Epicenter.Extra.tap(input, fn input -> send(self(), {:tap_called_me, input}) end) == input
      assert mailbox_contents() == [{:tap_called_me, input}]
    end
  end

  defp mailbox_contents() do
    mailbox_contents([])
  end

  defp mailbox_contents(acc) do
    receive do
      message -> mailbox_contents(acc ++ [message])
    after
      0 -> acc
    end
  end
end
