defmodule Epicenter.Extra.DateTimeTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

  describe "is_before?" do
    test "when the first datetime is before the second datetime" do
      assert Extra.DateTime.is_before?(~U[2020-01-01 11:59:59Z], ~U[2020-01-01 12:00:00Z])
    end

    test "when the first datetime is after the second datetime" do
      refute Extra.DateTime.is_before?(~U[2020-01-01 12:00:00Z], ~U[2020-01-01 11:59:59Z])
    end

    test "when the first datetime is the same as the second datetime" do
      refute Extra.DateTime.is_before?(~U[2020-01-01 12:00:00Z], ~U[2020-01-01 12:00:00Z])
    end
  end
end
