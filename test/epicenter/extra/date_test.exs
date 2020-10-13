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

  describe "days_ago_string" do
    test "when given a date, returns the number of days ago as a string" do
      assert Extra.Date.days_ago_string(~D[2020-05-19], from: ~D[2020-06-01]) == "13 days ago"
      assert Extra.Date.days_ago_string(~D[2020-05-19], from: ~D[2020-05-20]) == "1 day ago"
    end
  end

  describe "render" do
    test "when given a date, formats it as mm/dd/yyyy" do
      assert Extra.Date.render(~D[2020-05-19]) == "05/19/2020"
    end

    test "when given a nil, quietly renders an empty string" do
      assert Extra.Date.render(nil) == ""
    end
  end

  describe "NilFirst.compare" do
    test "nils are considered greater than date values" do
      assert Extra.Date.NilFirst.compare(nil, ~D[2020-05-19]) == :gt
      assert Extra.Date.NilFirst.compare(~D[2020-05-19], nil) == :lt
      assert Extra.Date.NilFirst.compare(nil, nil) == :eq
    end

    test "date value comparison is as per Date.compare" do
      assert Extra.Date.NilFirst.compare(~D[2020-05-19], ~D[2020-05-19]) == Date.compare(~D[2020-05-19], ~D[2020-05-19])
      assert Extra.Date.NilFirst.compare(~D[2020-05-18], ~D[2020-05-19]) == Date.compare(~D[2020-05-18], ~D[2020-05-19])
      assert Extra.Date.NilFirst.compare(~D[2020-05-19], ~D[2020-05-18]) == Date.compare(~D[2020-05-19], ~D[2020-05-18])
    end
  end
end
