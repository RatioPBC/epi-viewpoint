defmodule EpicenterWeb.Multiselect.SpecTest do
  use Epicenter.SimpleCase, async: true

  alias EpicenterWeb.Multiselect.Spec

  @test_spec [
    {:radio, "R1", "r1"},
    {:radio, "R2", "r2"},
    {:checkbox, "C1", "c1", [{:checkbox, "C1.1", "c1.1"}, {:checkbox, "C1.2", "c1.2"}]},
    {:checkbox, "C2", "c2"}
  ]

  describe "parent" do
    test "gets the parent if it exists" do
      assert Spec.parent("c1.1", @test_spec) == "c1"
    end
  end

  describe "type" do
    test "returns the type of the spec item if it exists" do
      assert Spec.type("c1", @test_spec) == :checkbox
      assert Spec.type("c1.1", @test_spec) == :checkbox
      assert Spec.type("r1", @test_spec) == :radio
    end

    test "handles keypath-value tuples too" do
      assert Spec.type({["major", "values"], "c1"}, @test_spec) == :checkbox
      assert Spec.type({["major", "values"], "c1.1"}, @test_spec) == :checkbox
      assert Spec.type({["major", "values"], "r1"}, @test_spec) == :radio
    end
  end
end
