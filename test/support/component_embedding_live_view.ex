defmodule EpicenterWeb.Test.ComponentEmbeddingLiveView do
  defmacro __using__(opts) do
    default_assigns = Keyword.get(opts, :default_assigns)

    quote do
      use EpicenterWeb, :live_view

      import EpicenterWeb.LiveComponent.Helpers
      import EpicenterWeb.LiveHelpers, only: [noreply: 1]

      def mount(_params, _session, socket) do
        {:ok, socket |> assign(unquote(default_assigns))}
      end

      def handle_info({:assigns, new_assigns}, socket) do
        socket |> assign(new_assigns) |> noreply()
      end
    end
  end
end
