defmodule Epicenter.Extra.DateTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

  describe "is_before?" do
    test "when the first datetime is before the second datetime" do
      assert Extra.NaiveDateTime.is_before?(~N[2020-01-01 11:59:59], ~N[2020-01-01 12:00:00])
    end

    test "when the first datetime is after the second datetime" do
      refute Extra.NaiveDateTime.is_before?(~N[2020-01-01 12:00:00], ~N[2020-01-01 11:59:59])
    end

    test "when the first datetime is the same as the second datetime" do
      refute Extra.NaiveDateTime.is_before?(~N[2020-01-01 12:00:00], ~N[2020-01-01 12:00:00])
    end
  end
end
