defmodule EpiViewpointWeb.Multiselect.ChangesetTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpointWeb.Multiselect.Changeset

  @test_spec [
    {:radio, "R1", "r1"},
    {:radio, "R2", "r2"},
    {:checkbox, "C1", "c1", [{:checkbox, "C1.1", "c1.1"}, {:checkbox, "C1.2", "c1.2"}]},
    {:checkbox, "C2", "c2"}
  ]

  describe "apply_event" do
    test "does nothing when nothing changes" do
      %{"major" => %{"values" => ["c1", "c2"]}}
      |> Changeset.apply_event(:nothing, @test_spec)
      |> assert_eq(%{"major" => %{"values" => ["c1", "c2"]}})
    end

    test "when a radio button is added, all other values are removed" do
      %{"major" => %{"values" => ["c1", "c2", "r1"]}}
      |> Changeset.apply_event({:add, :radio, ["major", "values"], "r1"}, @test_spec)
      |> assert_eq(%{"major" => %{"values" => "r1"}})
    end

    test "when a checkbox is added, all radio buttons are removed" do
      %{"major" => %{"values" => ["r1", "c1", "r2", "c2"]}}
      |> Changeset.apply_event({:add, :checkbox, ["major", "values"], "c1"}, @test_spec)
      |> assert_eq(%{"major" => %{"values" => ["c1", "c2"]}})
    end

    test "when a detailed checkbox is added, its major is checked" do
      %{"major" => %{"values" => ["c1"]}, "detailed" => %{"c2" => %{"values" => ["c2.1"]}}}
      |> Changeset.apply_event({:add, :checkbox, ["detailed", "c2", "values"], "c2.1"}, @test_spec)
      |> assert_eq(%{"major" => %{"values" => ["c1", "c2"]}, "detailed" => %{"c2" => %{"values" => ["c2.1"]}}})
    end

    test "when a major checkbox is removed, its detailed are removed" do
      %{"major" => %{"values" => ["c1"]}, "detailed" => %{"c1" => %{"values" => ["c1.1"]}, "c2" => %{"values" => ["c2.1"]}}}
      |> Changeset.apply_event({:remove, :checkbox, ["major", "values"], "c2"}, @test_spec)
      |> assert_eq(%{"major" => %{"values" => ["c1"]}, "detailed" => %{"c1" => %{"values" => ["c1.1"]}}})
    end

    test "when a major checkbox is removed, its 'other' checkbox and value are removed" do
      %{
        "_ignore" => %{"detailed" => %{"c1" => %{"other" => "true"}, "c2" => %{"other" => "true"}}},
        "major" => %{"values" => ["c1"]},
        "detailed" => %{"c1" => %{"other" => "other-c1", "values" => ["c1.1"]}, "c2" => %{"other" => "other-c2", "values" => ["c2.1"]}}
      }
      |> Changeset.apply_event({:remove, :checkbox, ["major", "values"], "c2"}, @test_spec)
      |> assert_eq(%{
        "_ignore" => %{"detailed" => %{"c1" => %{"other" => "true"}}},
        "major" => %{"values" => ["c1"]},
        "detailed" => %{"c1" => %{"other" => "other-c1", "values" => ["c1.1"]}}
      })
    end

    test "when a major 'other' checkbox is added, all radio buttons are removed" do
      %{"major" => %{"values" => ["r1", "r2", "c2"]}}
      |> Changeset.apply_event({:add, :other, ["detailed", "c1", "other"], "true"}, @test_spec)
      |> assert_eq(%{"major" => %{"values" => ["c2", "c1"]}})
    end

    test "when a major 'other' checkbox is removed, its 'other' value is removed" do
      %{
        "major" => %{"other" => "other-major", "values" => ["c1"]}
      }
      |> Changeset.apply_event({:remove, :other, ["major"], "other"}, @test_spec)
      |> assert_eq(%{
        "major" => %{"values" => ["c1"]}
      })
    end

    test "when a detailed 'other' checkbox is added, its parent is added" do
      %{}
      |> Changeset.apply_event({:add, :other, ["detailed", "c1", "other"], "true"}, @test_spec)
      |> assert_eq(%{"major" => %{"values" => ["c1"]}})
    end

    test "when a detailed 'other' checkbox is added, all radio buttons are removed" do
      %{"major" => %{"values" => ["r1", "r2", "c2"]}}
      |> Changeset.apply_event({:add, :other, ["detailed", "c1", "other"], "true"}, @test_spec)
      |> assert_eq(%{"major" => %{"values" => ["c2", "c1"]}})
    end

    test "when a detailed 'other' checkbox is removed, its 'other' value is removed" do
      %{
        "_ignore" => %{"detailed" => %{"c2" => %{"other" => "true"}}},
        "major" => %{"values" => ["c1"]},
        "detailed" => %{"c1" => %{"other" => "other-c1", "values" => ["c1.1"]}, "c2" => %{"other" => "other-c2", "values" => ["c2.1"]}}
      }
      |> Changeset.apply_event({:remove, :other, ["detailed", "c1"], "other"}, @test_spec)
      |> assert_eq(%{
        "_ignore" => %{"detailed" => %{"c2" => %{"other" => "true"}}},
        "major" => %{"values" => ["c1"]},
        "detailed" => %{"c1" => %{"values" => ["c1.1"]}, "c2" => %{"other" => "other-c2", "values" => ["c2.1"]}}
      })
    end
  end

  describe "event" do
    test "when nothing changes" do
      Changeset.event(
        %{"major" => %{"values" => ["c1", "c2"]}},
        %{"major" => %{"values" => ["c1", "c2"]}},
        ["major", "values"],
        @test_spec
      )
      |> assert_eq(:nothing)
    end

    test "when something was added" do
      Changeset.event(
        %{"major" => %{"values" => ["c1"]}},
        %{"major" => %{"values" => ["c1", "c2"]}},
        ["major", "values"],
        @test_spec
      )
      |> assert_eq({:add, :checkbox, ["major", "values"], "c2"})

      Changeset.event(
        %{"major" => %{"values" => ["r1"]}},
        %{"major" => %{"values" => ["r1", "r2"]}},
        ["major", "values"],
        @test_spec
      )
      |> assert_eq({:add, :radio, ["major", "values"], "r2"})
    end

    test "when something was removed" do
      Changeset.event(
        %{"major" => %{"values" => ["c1", "c2"]}},
        %{"major" => %{"values" => ["c1"]}},
        ["major", "values"],
        @test_spec
      )
      |> assert_eq({:remove, :checkbox, ["major", "values"], "c2"})

      Changeset.event(
        %{"major" => %{"values" => ["r1", "r2"]}},
        %{"major" => %{"values" => ["r1"]}},
        ["major", "values"],
        @test_spec
      )
      |> assert_eq({:remove, :radio, ["major", "values"], "r2"})
    end

    test "when something was added and something else was removed" do
      Changeset.event(
        %{"major" => %{"values" => ["c1", "r1"]}},
        %{"major" => %{"values" => ["c1", "r2"]}},
        ["major", "values"],
        @test_spec
      )
      |> assert_eq({:add, :radio, ["major", "values"], "r2"})
    end

    test "when a major 'other' checkbox was removed" do
      Changeset.event(
        %{"major" => %{"other" => "other-major", "values" => ["c1"]}},
        %{"major" => %{"other" => "other-major", "values" => ["c1"]}},
        ["_ignore", "major", "other"],
        @test_spec
      )
      |> assert_eq({:remove, :other, ["major"], "other"})
    end

    test "when a detailed 'other' checkbox was added" do
      Changeset.event(
        %{},
        %{"_ignore" => %{"detailed" => %{"c1" => %{"other" => "true"}}}},
        ["_ignore", "detailed", "c1", "other"],
        @test_spec
      )
      |> assert_eq({:add, :other, ["detailed", "c1", "other"], "true"})
    end

    test "when a major 'other' checkbox was added" do
      Changeset.event(
        %{},
        %{"_ignore" => %{"major" => %{"other" => "true"}}},
        ["_ignore", "major", "other"],
        @test_spec
      )
      |> assert_eq({:add, :other, ["major", "other"], "true"})
    end

    test "when a detailed 'other' checkbox was removed" do
      Changeset.event(
        %{"detailed" => %{"c1" => %{"other" => "other-c1"}}},
        %{"detailed" => %{"c1" => %{"other" => "other-c1"}}},
        ["_ignore", "detailed", "c1", "other"],
        @test_spec
      )
      |> assert_eq({:remove, :other, ["detailed", "c1"], "other"})
    end
  end

  describe "remove_all_radios" do
    test "removes all radios" do
      %{"major" => %{"values" => ["c1", "r1", "c2", "r2"]}}
      |> Changeset.remove_all_radios(@test_spec)
      |> assert_eq(%{"major" => %{"values" => ["c1", "c2"]}})
    end
  end

  describe "add_parent" do
    test "adds the parent if the keypath is for a detailed value" do
      %{"major" => %{"values" => ["r1"]}}
      |> Changeset.add_parent(["detailed", "c1", "values"])
      |> assert_eq(%{"major" => %{"values" => ["r1", "c1"]}})
    end

    test "does nothing if the keypath is not for a detailed value" do
      %{"major" => %{"values" => ["r1"]}}
      |> Changeset.add_parent(["major", "values"])
      |> assert_eq(%{"major" => %{"values" => ["r1"]}})
    end
  end
end
