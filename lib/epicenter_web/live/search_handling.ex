defmodule EpicenterWeb.SearchHandling do
  defmacro __using__(_params) do
    quote do
      def handle_event("close-search-results", params, socket),
        do: socket |> assign_search(nil, nil) |> EpicenterWeb.LiveHelpers.noreply()

      def handle_event("search", %{"search" => %{"term" => term}}, socket) do
        term = term |> String.trim()
        results = if String.length(term) < 3, do: nil, else: Epicenter.Cases.search_people(term, socket.assigns.current_user)

        socket |> assign_search(term, results) |> EpicenterWeb.LiveHelpers.noreply()
      end

      def handle_event("search-next", _, socket) do
        socket
        |> Phoenix.Component.assign(:search_results, EpicenterWeb.Pagination.next(socket.assigns.search_results))
        |> EpicenterWeb.LiveHelpers.noreply()
      end

      def handle_event("search-goto", %{"page" => page}, socket) do
        page = page |> Integer.parse() |> elem(0)

        socket
        |> Phoenix.Component.assign(:search_results, EpicenterWeb.Pagination.goto(socket.assigns.search_results, page))
        |> EpicenterWeb.LiveHelpers.noreply()
      end

      def handle_event("search-prev", _, socket) do
        socket
        |> Phoenix.Component.assign(:search_results, EpicenterWeb.Pagination.previous(socket.assigns.search_results))
        |> EpicenterWeb.LiveHelpers.noreply()
      end

      def assign_search(socket, term, results) do
        results = if results, do: EpicenterWeb.Pagination.new(results, per_page: 5), else: nil

        socket
        |> Phoenix.Component.assign(:search_term, term)
        |> Phoenix.Component.assign(:search_results, results)
      end
    end
  end
end
