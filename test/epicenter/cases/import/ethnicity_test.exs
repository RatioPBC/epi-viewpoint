defmodule Epicenter.Cases.Import.EthnicityTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Cases.Import.Ethnicity

  describe "build_attrs" do
    test "creates map of parent and children ethnicity values from row values" do
      %{"foo" => "bar", "ethnicity" => ""}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => "unknown", "children" => []}}, :simple)

      %{"foo" => "bar", "ethnicity" => "Unknown"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => "unknown", "children" => []}}, :simple)

      %{"foo" => "bar", "ethnicity" => "RefusedToAnswer"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => "declined_to_answer", "children" => []}}, :simple)

      %{"foo" => "bar", "ethnicity" => "NonHispanicOrNonLatino"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => "not_hispanic", "children" => []}}, :simple)

      %{"foo" => "bar", "ethnicity" => "HispanicOrLatino"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => "hispanic", "children" => []}}, :simple)
    end

    test "defaults to unknown if there is no ethnicity value" do
      %{"foo" => "bar", "baz" => "bat"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "baz" => "bat", "ethnicity" => %{"parent" => "unknown", "children" => []}}, :simple)
    end
  end
end
