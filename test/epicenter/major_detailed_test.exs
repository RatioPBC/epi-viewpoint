defmodule Epicenter.MajorDetailedTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.MajorDetailed

  defmodule TestStruct do
    defstruct ~w{race race_other}a
  end

  describe "combine" do
    test "combines a bunch of fields into a MajorDetailed map" do
      %{
        race: ["asian", "black_or_african_american", "native_hawaiian_or_other_pacific_islander"],
        race_other: "Some other race",
        race_asian: ["filipino", "korean"],
        race_asian_other: "Some other asian",
        race_native_hawaiian_or_other_pacific_islander: ["samoan"],
        race_native_hawaiian_or_other_pacific_islander_other: "Other pacific islander"
      }
      |> MajorDetailed.combine(:race)
      |> assert_eq(
        %{
          "asian" => ["Some other asian", "filipino", "korean"],
          "black_or_african_american" => nil,
          "native_hawaiian_or_other_pacific_islander" => ["Other pacific islander", "samoan"],
          "Some other race" => nil
        },
        :simple
      )
    end

    test "works on structs too" do
      %TestStruct{race: ["asian"], race_other: "Other"}
      |> MajorDetailed.combine(:race)
      |> assert_eq(%{"asian" => nil, "Other" => nil}, :simple)
    end

    test "deals with nils" do
      %{
        "race" => ["asian"],
        "race_asian" => nil,
        "race_asian_other" => nil,
        "race_native_hawaiian_or_other_pacific_islander_other" => nil,
        "race_other" => nil
      }
      |> MajorDetailed.combine(:race)
      |> assert_eq(%{"asian" => nil}, :simple)
    end
  end

  describe "split" do
    test "splits a MajorDetailed map up into multiple fields" do
      standard_values = [
        {"Unknown", "unknown", nil},
        {"Declined to answer", "declined_to_answer", nil},
        {"White", "white", nil},
        {"Black or African American", "black_or_african_american", nil},
        {"American Indian or Alaska Native", "american_indian_or_alaska_native", nil},
        {"Asian", "asian", nil},
        {"Asian Indian", "asian_indian", "asian"},
        {"Chinese", "chinese", "asian"},
        {"Filipino", "filipino", "asian"},
        {"Japanese", "japanese", "asian"},
        {"Korean", "korean", "asian"},
        {"Vietnamese", "vietnamese", "asian"},
        {"Native Hawaiian or Other Pacific Islander", "native_hawaiian_or_other_pacific_islander", nil},
        {"Native Hawaiian", "native_hawaiian", "native_hawaiian_or_other_pacific_islander"},
        {"Guamanian or Chamorro", "guamanian_or_chamorro", "native_hawaiian_or_other_pacific_islander"},
        {"Samoan", "samoan", "native_hawaiian_or_other_pacific_islander"}
      ]

      %{
        race: %{
          "black_or_african_american" => nil,
          "asian" => ["filipino", "korean", "Some other asian"],
          "native_hawaiian_or_other_pacific_islander" => ["samoan"],
          "Some other race" => nil
        }
      }
      |> MajorDetailed.split(:race, standard_values)
      |> assert_eq(
        %{
          race: ["asian", "black_or_african_american", "native_hawaiian_or_other_pacific_islander"],
          race_other: "Some other race",
          race_asian: ["filipino", "korean"],
          race_asian_other: "Some other asian",
          race_native_hawaiian_or_other_pacific_islander: "samoan"
        },
        :simple
      )
    end

    test "when the key doesn't exist in the map" do
      %{foo: %{}} |> MajorDetailed.split(:race, []) |> assert_eq(%{})
    end

    test "when the value for the key is nil" do
      %{race: nil} |> MajorDetailed.split(:race, []) |> assert_eq(%{})
    end
  end
end
