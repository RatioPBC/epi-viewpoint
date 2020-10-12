defmodule Epicenter.DateParserTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.DateParser

  describe "parse_mm_dd_yyyy" do
    test "mm-dd-yyyy and mm/dd/yyyy work" do
      assert DateParser.parse_mm_dd_yyyy("06-01-2020") == {:ok, ~D[2020-06-01]}
      assert DateParser.parse_mm_dd_yyyy("06/01/2020") == {:ok, ~D[2020-06-01]}
      assert DateParser.parse_mm_dd_yyyy("6/1/2020") == {:ok, ~D[2020-06-01]}
    end

    test "other formats fail" do
      assert DateParser.parse_mm_dd_yyyy("06#01#2020") == {:error, [user_readable: "Invalid mm-dd-yyyy format: 06#01#2020"]}
      assert DateParser.parse_mm_dd_yyyy("06012020") == {:error, [user_readable: "Invalid mm-dd-yyyy format: 06012020"]}
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
