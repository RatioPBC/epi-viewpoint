defmodule EpiViewpointWeb.LiveHelpersTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpointWeb.LiveHelpers
  alias Phoenix.LiveView.Socket

  describe "assign_defaults" do
    test "assigns default values" do
      assert %{assigns: %{body_class: "body-background-none", show_nav: true}} = LiveHelpers.assign_defaults(%Socket{})
    end

    test "can be overriden" do
      assert %{assigns: %{body_class: "body-background-none", show_nav: false}} = LiveHelpers.assign_defaults(%Socket{}, show_nav: false)
    end

    test "doesn't overwrite existing assigns" do
      assert %{assigns: %{body_class: "original-body-class", show_nav: "original-show-nav"}} =
               LiveHelpers.assign_defaults(%Socket{assigns: %{body_class: "original-body-class", show_nav: "original-show-nav"}})
    end
  end
end
