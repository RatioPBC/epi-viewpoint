defmodule Epicenter.Extra.DateTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

  describe "days_ago" do
    test "when given an integer, returns a date that's some number of days ago" do
      assert Extra.Date.days_ago(13, from: ~D[2020-06-01]) == ~D[2020-05-19]
    end

    test "when given a date, returns the number of days ago that date was" do
      assert Extra.Date.days_ago(~D[2020-05-19], from: ~D[2020-06-01]) == 13
    end

    test "when given nil, returns nil" do
      assert Extra.Date.days_ago(nil) == nil
    end
  end
end
