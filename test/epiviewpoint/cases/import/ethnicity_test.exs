defmodule EpiViewpoint.Cases.Import.EthnicityTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpoint.Cases.Import.Ethnicity

  describe "build_attrs" do
    test "creates map of major and detailed ethnicity values from row values" do
      %{"foo" => "bar", "ethnicity" => ""}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"major" => "unknown", "detailed" => []}})

      %{"foo" => "bar", "ethnicity" => "Unknown"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"major" => "unknown", "detailed" => []}})

      %{"foo" => "bar", "ethnicity" => "RefusedToAnswer"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"major" => "declined_to_answer", "detailed" => []}})

      %{"foo" => "bar", "ethnicity" => "NonHispanicOrNonLatino"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"major" => "not_hispanic_latinx_or_spanish_origin", "detailed" => []}})

      %{"foo" => "bar", "ethnicity" => "HispanicOrLatino"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"major" => "hispanic_latinx_or_spanish_origin", "detailed" => []}})
    end

    test "defaults to unknown if there is no ethnicity value" do
      %{"foo" => "bar", "baz" => "bat"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "baz" => "bat", "ethnicity" => %{"major" => "unknown", "detailed" => []}})
    end
  end
end
