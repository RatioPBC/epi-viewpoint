defmodule Epicenter.Extra.StringTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra

  describe "dasherize" do
    test "stringifies and converts underscores to dashes" do
      assert Extra.String.dasherize("foo") == "foo"
      assert Extra.String.dasherize(:foo) == "foo"
      assert Extra.String.dasherize("foo bar") == "foo bar"
      assert Extra.String.dasherize("foo_bar_baz") == "foo-bar-baz"
      assert Extra.String.dasherize(:foo_bar_baz) == "foo-bar-baz"
    end

    test "with a list, flattens and dasherizes each item and joins with a dash" do
      assert Extra.String.dasherize(["foo", :bar, :baz_fez]) == "foo-bar-baz-fez"
      assert Extra.String.dasherize(["foo", :bar, [:baz, "fez"]]) == "foo-bar-baz-fez"
    end
  end

  describe "is_existing_atom?" do
    test "returns true if the given string matches an existing atom" do
      string = Euclid.Extra.Random.string()
      _ = String.to_atom(string)
      assert Extra.String.is_existing_atom?(string)
    end

    test "returns false if the given string does not match an existing atom" do
      string = Euclid.Extra.Random.string()
      refute Extra.String.is_existing_atom?(string)
    end
  end

  describe "pluralize" do
    test "zero", do: assert(Extra.String.pluralize(0, "nerd", "nerds") == "0 nerds")
    test "one", do: assert(Extra.String.pluralize(1, "nerd", "nerds") == "1 nerd")
    test "many", do: assert(Extra.String.pluralize(2, "nerd", "nerds") == "2 nerds")
  end

  describe "remove_marked_whitespace" do
    test "removes whitespace following backslash-v" do
      """
      ant bat\v cat dog\v
          eel fox\v  \t \r

        gnu
      """
      |> Extra.String.remove_marked_whitespace()
      |> assert_eq("ant batcat dogeel foxgnu\n")
    end
  end

  describe "remove_non_numbers" do
    test "doesn't blow up on nil" do
      assert Extra.String.remove_non_numbers(nil) == nil
    end

    test "removes things that aren't numbers" do
      assert " a 1 - b2/34  5?6" |> Extra.String.remove_non_numbers() == "123456"
    end
  end

  describe "squish" do
    test "removes whitespace" do
      assert " foo  BAR  \t baz \n FEz    " |> Extra.String.squish() == "foo BAR baz FEz"
    end

    test "allows nil" do
      nil |> Extra.String.squish() |> assert_eq(nil)
    end
  end

  describe "trim" do
    test "doesn't blow up on nil" do
      assert Extra.String.trim(nil) == nil
    end

    test "trims from left and right" do
      assert Extra.String.trim("  foo  ") == "foo"
    end
  end

  describe "underscore" do
    test "stringifies and converts dashes to underscores" do
      assert Extra.String.underscore("foo") == "foo"
      assert Extra.String.underscore("foo bar") == "foo bar"
      assert Extra.String.underscore("foo-bar-baz") == "foo_bar_baz"
    end

    test "with a list, underscores each item and joins with an underscore" do
      assert Extra.String.underscore(["foo", :bar, "baz-fez"]) == "foo_bar_baz_fez"
    end

    test "handles nils and blank strings" do
      assert Extra.String.underscore(nil) == ""
      assert Extra.String.underscore("") == ""
      assert Extra.String.underscore(["foo", nil, "bar", "", "baz"]) == "foo_bar_baz"
    end
  end
end
