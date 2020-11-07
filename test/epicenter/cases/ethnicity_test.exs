defmodule Epicenter.Cases.EthnicityTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Cases.Ethnicity

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
