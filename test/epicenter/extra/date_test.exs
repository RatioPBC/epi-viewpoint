defmodule Epicenter.Extra.DateTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

  describe "days_ago" do
    test "returns a date that's some number of days ago" do
      assert Extra.Date.days_ago(13, from: ~D[2020-06-01]) == ~D[2020-05-19]
    end
  end
end
