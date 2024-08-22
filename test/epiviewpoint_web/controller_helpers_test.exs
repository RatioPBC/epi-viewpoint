defmodule EpiViewpointWeb.ControllerHelpersTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpointWeb.ControllerHelpers

  describe "assign_defaults" do
    test "assigns default values" do
      assert %{assigns: %{body_class: "body-background-none", show_nav: true}} = ControllerHelpers.assign_defaults(%Plug.Conn{})
    end

    test "can be overriden" do
      assert %{assigns: %{body_class: "body-background-none", show_nav: false}} = ControllerHelpers.assign_defaults(%Plug.Conn{}, show_nav: false)
    end

    test "doesn't overwrite existing assigns" do
      assert %{assigns: %{body_class: "original-body-class", show_nav: "original-show-nav"}} =
               ControllerHelpers.assign_defaults(%Plug.Conn{assigns: %{body_class: "original-body-class", show_nav: "original-show-nav"}})
    end
  end
end
