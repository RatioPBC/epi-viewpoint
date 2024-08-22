defmodule EpiViewpointWeb.Presenters.GeographyPresenterTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpointWeb.Presenters.GeographyPresenter

  describe "states" do
    test "returns a list of states tuples" do
      "TS"
      |> GeographyPresenter.states()
      |> Enum.each(fn
        {"", nil} ->
          # pass
          nil

        state_tuple ->
          assert {state, state} = state_tuple
      end)
    end

    test "includes the passed-in current state" do
      assert {"TS", "TS"} in GeographyPresenter.states("TS")
    end

    test "includes blank state" do
      assert {"", nil} in GeographyPresenter.states(nil)
      assert {"", nil} in GeographyPresenter.states("TS")
    end

    test "does not duplicate existing states" do
      GeographyPresenter.states("OH")
      |> Enum.count(fn state_tuple -> {"OH", "OH"} == state_tuple end)
      |> assert_eq(1)
    end
  end
end
