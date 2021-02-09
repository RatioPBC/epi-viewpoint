defmodule EpicenterWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use EpicenterWeb, :controller
      use EpicenterWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: EpicenterWeb

      import Plug.Conn
      import Epicenter.Gettext
      alias EpicenterWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/epicenter_web/templates",
        namespace: EpicenterWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use PhoenixSlime.LiveView.CollocatedTemplate, extension: :slive
      use Phoenix.HTML
      use Phoenix.LiveView, layout: {EpicenterWeb.LayoutView, "live.html"}

      unquote(view_helpers())

      def handle_event("close-search-results", params, socket),
        do: socket |> assign_search(nil, nil) |> EpicenterWeb.LiveHelpers.noreply()

      def handle_event("search", %{"search" => %{"term" => term}}, socket) do
        term = term |> String.trim()
        results = if String.length(term) < 3, do: nil, else: Epicenter.Cases.search_people(term, socket.assigns.current_user)

        socket |> assign_search(term, results) |> EpicenterWeb.LiveHelpers.noreply()
      end

      def assign_search(socket, term, results) do
        results = if results, do: EpicenterWeb.Pagination.new(results, per_page: 5), else: nil

        socket
        |> Phoenix.LiveView.assign(:search_term, term)
        |> Phoenix.LiveView.assign(:search_results, results)
      end
    end
  end

  def live_component do
    quote do
      use PhoenixSlime.LiveView.CollocatedTemplate, extension: :slive
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      use Plug.ErrorHandler
      use EpicenterWeb.ErrorHandler

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import Epicenter.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, component, live_patch, etc)
      import Phoenix.LiveView.Helpers
      import EpicenterWeb.SlimeSigilWrapper
      import EpicenterWeb.LiveComponent.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import Epicenter.Gettext
      import EpicenterWeb.ErrorHelpers
      alias EpicenterWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
