defmodule Epicenter.DateParserTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.DateParser

  describe "parse_mm_dd_yyyy" do
    test "mm-dd-yyyy and mm/dd/yyyy work" do
      assert DateParser.parse_mm_dd_yyyy("06-01-2020") == {:ok, ~D[2020-06-01]}
      assert DateParser.parse_mm_dd_yyyy("06/01/2020") == {:ok, ~D[2020-06-01]}
    end

    test "other formats fail" do
      assert DateParser.parse_mm_dd_yyyy("06#01#2020") == {:error, "Invalid mm-dd-yyyy format: 06#01#2020"}
      assert DateParser.parse_mm_dd_yyyy("06012020") == {:error, "Invalid mm-dd-yyyy format: 06012020"}
      assert DateParser.parse_mm_dd_yyyy("2020-06-01") == {:error, "Invalid mm-dd-yyyy format: 2020-06-01"}
      assert DateParser.parse_mm_dd_yyyy("glorp") == {:error, "Invalid mm-dd-yyyy format: glorp"}
    end

    test "has a ! version" do
      assert DateParser.parse_mm_dd_yyyy!("06-01-2020") == ~D[2020-06-01]
      assert_raise RuntimeError, "Invalid mm-dd-yyyy format: glorp", fn -> DateParser.parse_mm_dd_yyyy!("glorp") end
    end
  end
end
