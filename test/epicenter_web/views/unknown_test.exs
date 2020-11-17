defmodule EpicenterWeb.UnknownTest do
  use Epicenter.SimpleCase, async: true

  alias EpicenterWeb.Unknown

  describe "string_or_unknown" do
    test "if the value is present, returns the string" do
      Unknown.string_or_unknown("something")
      |> assert_html_eq("something")
    end

    test "if the value is not present, returns 'Unknown' or the given text" do
      Unknown.string_or_unknown(nil)
      |> assert_html_eq(~s|<span class="unknown">Unknown</span>|)

      Unknown.string_or_unknown("")
      |> assert_html_eq(~s|<span class="unknown">Unknown</span>|)

      Unknown.string_or_unknown("", "Not known")
      |> assert_html_eq(~s|<span class="unknown">Not known</span>|)
    end
  end

  describe "list_or_unknown" do
    test "if there are values, returns a UL with each value as a list item" do
      Unknown.list_or_unknown(["ant", "bat", "cat"])
      |> assert_html_eq(~s|<ul><li>ant</li><li>bat</li><li>cat</li></ul>|)
    end

    test "excludes blank values" do
      Unknown.list_or_unknown(["ant", nil, "bat", "", "cat"])
      |> assert_html_eq(~s|<ul><li>ant</li><li>bat</li><li>cat</li></ul>|)
    end

    test "if there are no values, returns 'Unknown'" do
      Unknown.list_or_unknown(nil)
      |> assert_html_eq(~s|<span class="unknown">Unknown</span>|)

      Unknown.list_or_unknown([])
      |> assert_html_eq(~s|<span class="unknown">Unknown</span>|)

      Unknown.list_or_unknown([nil])
      |> assert_html_eq(~s|<span class="unknown">Unknown</span>|)
    end
  end
end
