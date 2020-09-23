defmodule EpicenterWeb.StyleguideLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView

  def mount(_params, _session, socket) do
    socket |> assign(show_nav: false) |> assign_address() |> clear_suggestions() |> ok()
  end

  def handle_event("choose-address", %{"address" => address}, socket) do
    socket |> assign_address(address) |> clear_suggestions() |> noreply()
  end

  def handle_event("suggest-address", %{"address" => address}, socket) do
    socket |> assign_address(address) |> assign_suggestions(address) |> noreply()
  end

  # # #

  defp assign_address(socket, address \\ "") do
    socket |> assign(address: address)
  end

  defp assign_suggestions(socket, address) do
    socket |> assign(suggested_addresses: suggest_address(address))
  end

  defp clear_suggestions(socket) do
    socket |> assign(suggested_addresses: [])
  end

  defp ok(socket), do: {:ok, socket}
  defp noreply(socket), do: {:noreply, socket}

  # # #

  @address_data EpicenterWeb.StyleguideData.generate_address_data()

  defp suggest_address(""), do: []

  defp suggest_address(address) do
    downcased_address = String.downcase(address)

    @address_data
    |> Enum.filter(fn address -> address |> String.downcase() |> String.contains?(downcased_address) end)
    |> Enum.slice(0..10)
  end
end
