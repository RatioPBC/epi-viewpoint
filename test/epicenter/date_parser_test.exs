defmodule Epicenter.DateParserTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.DateParser

  describe "parse_mm_dd_yyyy" do
    test "mm-dd-yyyy and mm/dd/yyyy work" do
      assert DateParser.parse_mm_dd_yyyy("06-01-2020") == {:ok, ~D[2020-06-01]}
      assert DateParser.parse_mm_dd_yyyy("06/01/2020") == {:ok, ~D[2020-06-01]}
      assert DateParser.parse_mm_dd_yyyy("6/1/2020") == {:ok, ~D[2020-06-01]}
    end

    test "mm-dd-yy and mm/dd/yy work" do
      assert DateParser.parse_mm_dd_yyyy("06-01-20") == {:ok, ~D[2020-06-01]}
      assert DateParser.parse_mm_dd_yyyy("06/01/20") == {:ok, ~D[2020-06-01]}
      assert DateParser.parse_mm_dd_yyyy("6/1/20") == {:ok, ~D[2020-06-01]}
    end

    test "when given a two digit year, and the year is <= the current two digit year, treat it as this century" do
      current_year = Date.utc_today().year
      hundred_years_ago = current_year - 100
      current_two_digit_year = rem(current_year, 100)
      last_two_digit_year = current_two_digit_year - 1
      next_two_digit_year = current_two_digit_year + 1

      assert DateParser.parse_mm_dd_yyyy("06-01-#{last_two_digit_year}") == Date.new(current_year - 1, 6, 1)
      assert DateParser.parse_mm_dd_yyyy("06/01/#{current_two_digit_year}") == Date.new(current_year, 6, 1)
      assert DateParser.parse_mm_dd_yyyy("6/1/#{next_two_digit_year}") == Date.new(hundred_years_ago + 1, 6, 1)
    end

    test "other formats fail" do
      assert DateParser.parse_mm_dd_yyyy("06#01#2020") == {:error, [user_readable: "Invalid mm-dd-yyyy format: 06#01#2020"]}
      assert DateParser.parse_mm_dd_yyyy("06012020") == {:error, [user_readable: "Invalid mm-dd-yyyy format: 06012020"]}
      assert DateParser.parse_mm_dd_yyyy("01/01/197") == {:error, [user_readable: "Invalid mm-dd-yyyy format: 01/01/197"]}
      assert DateParser.parse_mm_dd_yyyy("2020-06-01") == {:error, [user_readable: "Invalid mm-dd-yyyy format: 2020-06-01"]}
      assert DateParser.parse_mm_dd_yyyy("glorp") == {:error, [user_readable: "Invalid mm-dd-yyyy format: glorp"]}
    end

    test "accepts a Date" do
      assert DateParser.parse_mm_dd_yyyy(~D[2020-06-01]) == {:ok, ~D[2020-06-01]}
    end

    test "has a ! version" do
      assert DateParser.parse_mm_dd_yyyy!("06-01-2020") == ~D[2020-06-01]
      assert_raise Epicenter.DateParsingError, "Invalid mm-dd-yyyy format: glorp", fn -> DateParser.parse_mm_dd_yyyy!("glorp") end
    end
  end
end
