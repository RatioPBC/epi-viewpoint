defmodule Epicenter.Cases.Import.EthnicityTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Cases.Import.Ethnicity

  describe "build_attrs" do
    test "creates map of parent and children ethnicity values from row values" do
      %{"foo" => "bar", "ethnicity" => ""}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => nil, "children" => nil}}, :simple)

      %{"foo" => "bar", "ethnicity" => "Unknown"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => nil, "children" => nil}}, :simple)

      %{"foo" => "bar", "ethnicity" => "RefusedToAnswer"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => "Declined to answer", "children" => []}}, :simple)

      %{"foo" => "bar", "ethnicity" => "NonHispanicOrNonLatino"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => "Not Hispanic, Latino/a, or Spanish origin", "children" => []}}, :simple)

      %{"foo" => "bar", "ethnicity" => "HispanicOrLatino"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => "Hispanic, Latino/a, or Spanish origin", "children" => []}}, :simple)
    end

    test "does nothing crazy if there is no ethnicity value" do
      %{"foo" => "bar", "baz" => "bat"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "baz" => "bat"}, :simple)
    end
  end
end
