defmodule Epicenter.Cases.Import.EthnicityTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Cases.Import.Ethnicity

  describe "build_attrs" do
    test "creates map of parent and children ethnicity values from row values" do
      %{"foo" => "bar", "ethnicity" => "Cuban"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "ethnicity" => %{"parent" => "Cuban", "children" => []}}, :simple)
    end

    test "does nothing crazy if there is no ethnicity value" do
      %{"foo" => "bar", "baz" => "bat"}
      |> Ethnicity.build_attrs()
      |> assert_eq(%{"foo" => "bar", "baz" => "bat"}, :simple)
    end
  end
end
