defmodule EpiViewpointWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use EpiViewpointWeb, :controller
      use EpiViewpointWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: EpiViewpointWeb

      import Plug.Conn
      import EpiViewpoint.Gettext
      use Phoenix.VerifiedRoutes, endpoint: EpiViewpointWeb.Endpoint, router: EpiViewpointWeb.Router
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/epiviewpoint_web/templates",
        namespace: EpiViewpointWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers
      use Phoenix.LiveView, layout: {EpiViewpointWeb.LayoutView, :live}
      use EpiViewpointWeb.SearchHandling
      use Phoenix.VerifiedRoutes, endpoint: EpiViewpointWeb.Endpoint, router: EpiViewpointWeb.Router

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      use Plug.ErrorHandler
      use EpiViewpointWeb.ErrorHandler

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import EpiViewpoint.Gettext
    end
  end

  def presenter do
    quote do
      use Phoenix.Component
      use Phoenix.VerifiedRoutes, endpoint: EpiViewpointWeb.Endpoint, router: EpiViewpointWeb.Router
      alias EpiViewpointWeb.Format
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      # Import LiveView helpers (live_render, component, live_patch, etc)
      import Phoenix.LiveView.Helpers
      import Phoenix.Component

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import EpiViewpoint.Gettext
      import EpiViewpointWeb.ErrorHelpers
      use Phoenix.VerifiedRoutes, endpoint: EpiViewpointWeb.Endpoint, router: EpiViewpointWeb.Router
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
