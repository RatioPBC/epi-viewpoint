defmodule Epicenter.MajorDetailedTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.MajorDetailed

  defmodule TestStruct do
    defstruct ~w{major detailed}a
  end

  describe "clean" do
    test "removes empty fields, and converts keys to strings" do
      %{
        :detailed => %{
          "asian" => %{"other" => ""},
          "native_hawaiian_or_other_pacific_islander" => %{"other" => "Other PI"}
        },
        "major" => %{:other => "", :values => ["asian", "black_or_african_american"]}
      }
      |> MajorDetailed.clean()
      |> assert_eq(%{
        "major" => %{"values" => ["asian", "black_or_african_american"]},
        "detailed" => %{"native_hawaiian_or_other_pacific_islander" => %{"other" => "Other PI"}}
      })
    end

    test "empty state" do
      nil |> MajorDetailed.clean() |> assert_eq(%{})
    end
  end

  describe "for_form" do
    test "extracts standard and non-standard values into 'values' and 'other' lists" do
      standard_values = [
        "black_or_african_american",
        "asian",
        "chinese",
        "filipino",
        "native_hawaiian_or_other_pacific_islander"
      ]

      %{
        major: ["Other race", "asian", "black_or_african_american", "native_hawaiian_or_other_pacific_islander"],
        detailed: %{asian: ["chinese", "filipino"], native_hawaiian_or_other_pacific_islander: ["Other PI"]}
      }
      |> MajorDetailed.for_form(standard_values)
      |> assert_eq(%{
        "major" => %{"other" => "Other race", "values" => ["asian", "black_or_african_american", "native_hawaiian_or_other_pacific_islander"]},
        "detailed" => %{"asian" => %{"values" => ["chinese", "filipino"]}, "native_hawaiian_or_other_pacific_islander" => %{"other" => "Other PI"}}
      })
    end

    test "handles nil and scalar values" do
      %{major: ["blue"], detailed: nil}
      |> MajorDetailed.for_form(["blue"])
      |> assert_eq(%{"major" => %{"values" => ["blue"]}, "detailed" => %{}})
    end

    test "when given a struct, converts into a map" do
      %TestStruct{major: ["blue"], detailed: %{"blue" => ["cyan", "powder blue"]}}
      |> MajorDetailed.for_form(["blue", "cyan"])
      |> assert_eq(%{
        "major" => %{"values" => ["blue"]},
        "detailed" => %{"blue" => %{"values" => ["cyan"], "other" => "powder blue"}}
      })
    end

    test "also supports 'major' as a string and 'detailed' as a list" do
      %TestStruct{major: "blue", detailed: ["cyan", "powder blue"]}
      |> MajorDetailed.for_form(["blue", "cyan"])
      |> assert_eq(%{
        "major" => %{"values" => ["blue"]},
        "detailed" => %{"blue" => %{"values" => ["cyan"], "other" => "powder blue"}}
      })
    end

    test "when given a list, uses the list as 'major' and 'other' values" do
      ["ant", "bat", "car"]
      |> MajorDetailed.for_form(["ant", "bat"])
      |> assert_eq(%{"major" => %{"values" => ["ant", "bat"], "other" => "car"}, "detailed" => %{}})
    end

    test "empty state" do
      nil
      |> MajorDetailed.for_form([])
      |> assert_eq(%{"major" => %{}, "detailed" => %{}})

      %{}
      |> MajorDetailed.for_form([])
      |> assert_eq(%{"major" => %{}, "detailed" => %{}})

      %{"major" => [], "detailed" => %{}}
      |> MajorDetailed.for_form([])
      |> assert_eq(%{"major" => %{}, "detailed" => %{}})
    end
  end

  describe "for_model(_, :map)" do
    test "collapses 'values' and 'other' lists into a map" do
      %{
        major: %{values: ["asian", "black_or_african_american"], other: "Other race"},
        detailed: %{
          asian: %{values: ["chinese", "filipino"], other: ""},
          native_hawaiian_or_other_pacific_islander: %{values: [], other: "Other PI"}
        }
      }
      |> MajorDetailed.for_model(:map)
      |> assert_eq(%{
        "major" => ["Other race", "asian", "black_or_african_american"],
        "detailed" => %{"asian" => ["chinese", "filipino"], "native_hawaiian_or_other_pacific_islander" => ["Other PI"]}
      })
    end

    test "empty state" do
      %{
        "detailed" => %{
          "asian" => %{"other" => ""},
          "native_hawaiian_or_other_pacific_islander" => %{"other" => ""}
        },
        "major" => %{"other" => ""}
      }
      |> MajorDetailed.for_model(:map)
      |> assert_eq(%{"major" => [], "detailed" => %{}})
    end
  end

  describe "for_model(_, :list)" do
    test "collapses 'values' and 'other' lists into a list" do
      %{
        major: %{values: ["asian", "black_or_african_american"], other: "Other race"},
        detailed: %{}
      }
      |> MajorDetailed.for_model(:list)
      |> assert_eq(["Other race", "asian", "black_or_african_american"])
    end

    test "blows up when there are 'detailed' values" do
      assert_raise RuntimeError, "Detailed values not allowed when converting to a list", fn ->
        %{
          major: %{values: ["asian", "black_or_african_american"], other: "Other race"},
          detailed: %{asian: %{values: ["filipino"]}}
        }
        |> MajorDetailed.for_model(:list)
      end
    end

    test "empty state" do
      %{"major" => %{"values" => [], "other" => ""}} |> MajorDetailed.for_model(:list) |> assert_eq([])
    end
  end

  describe "for_display" do
    test "returns a collapsed list" do
      %{
        major: ["Other race", "asian", "black_or_african_american", "native_hawaiian_or_other_pacific_islander"],
        detailed: %{asian: ["chinese", "filipino"], native_hawaiian_or_other_pacific_islander: ["Other PI"]}
      }
      |> MajorDetailed.for_display()
      |> assert_eq(
        ["Other race", "asian", "black_or_african_american", "native_hawaiian_or_other_pacific_islander", "chinese", "filipino", "Other PI"],
        ignore_order: true
      )
    end

    test "empty state" do
      %{major: [], detailed: %{}} |> MajorDetailed.for_display() |> assert_eq([])
    end
  end
end
