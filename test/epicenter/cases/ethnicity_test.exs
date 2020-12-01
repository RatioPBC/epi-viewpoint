defmodule Epicenter.Cases.EthnicityTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Cases.Ethnicity

  describe "from_major_detailed converts MajorDetailed map to Ethnicity" do
    test "with major" do
      %{
        "detailed" => %{},
        "major" => ["not_hispanic_latinx_or_spanish_origin"]
      }
      |> Ethnicity.from_major_detailed()
      |> assert_eq(%{"major" => "not_hispanic_latinx_or_spanish_origin", "detailed" => nil})
    end

    test "with major and detailed" do
      %{
        "detailed" => %{"hispanic_latinx_or_spanish_origin" => ["cuban", "puerto_rican"]},
        "major" => ["hispanic_latinx_or_spanish_origin"]
      }
      |> Ethnicity.from_major_detailed()
      |> assert_eq(%{"major" => "hispanic_latinx_or_spanish_origin", "detailed" => ["cuban", "puerto_rican"]})
    end

    test "empty case" do
      %{} |> Ethnicity.from_major_detailed() |> assert_eq(nil)
      %{"major" => []} |> Ethnicity.from_major_detailed() |> assert_eq(nil)
      %{"detailed" => %{}} |> Ethnicity.from_major_detailed() |> assert_eq(nil)
      %{"major" => [], "detailed" => %{}} |> Ethnicity.from_major_detailed() |> assert_eq(nil)
    end
  end

  describe "major" do
    test "returns nil if there is no ethnicity or if the major ethnicity is nil" do
      assert Ethnicity.major(nil) == nil
      assert Ethnicity.major(%Ethnicity{major: nil}) == nil
    end

    test "returns the major ethnicity if it exists" do
      assert Ethnicity.major(%Ethnicity{major: "declined_to_answer"}) == "declined_to_answer"
    end
  end

  describe "hispanic_latinx_or_spanish_origin" do
    test "returns nil if there is no ethnicity or if the major ethnicity is nil" do
      assert Ethnicity.hispanic_latinx_or_spanish_origin(nil) == nil
      assert Ethnicity.hispanic_latinx_or_spanish_origin(%Ethnicity{major: nil}) == nil
    end

    test "returns the detailed value if major is 'hispanic_latinx_or_spanish_origin'" do
      %Ethnicity{major: "hispanic_latinx_or_spanish_origin", detailed: ["Cuban", "Puerto Rican"]}
      |> Ethnicity.hispanic_latinx_or_spanish_origin()
      |> assert_eq(["Cuban", "Puerto Rican"])
    end

    test "returns nil if major is not 'hispanic_latinx_or_spanish_origin'" do
      %Ethnicity{major: "not_hispanic_latinx_or_spanish_origin", detailed: ["Other"]}
      |> Ethnicity.hispanic_latinx_or_spanish_origin()
      |> assert_eq(nil)
    end
  end
end
