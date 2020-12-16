defmodule EpicenterWeb.Styleguide.StyleguideLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, noreply: 1, ok: 1]
  import EpicenterWeb.IconView

  defmodule StyleguideSchema do
    use Ecto.Schema

    embedded_schema do
      field :first_name, :string
      field :last_name, :string
      field :email, :string
      field :full_address, :string
    end
  end

  def mount(_params, _session, socket) do
    socket
    |> assign_defaults()
    |> assign_page_title("Styleguide")
    |> assign(show_nav: false)
    |> assign_changeset()
    |> assign_address()
    |> clear_suggestions()
    |> ok()
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

  defp assign_changeset(socket) do
    changeset = %StyleguideSchema{} |> Ecto.Changeset.change() |> Ecto.Changeset.validate_required([:email])
    socket |> assign(changeset: %{changeset | action: :insert})
  end

  defp assign_suggestions(socket, address) do
    socket |> assign(suggested_addresses: suggest_address(address))
  end

  defp clear_suggestions(socket) do
    socket |> assign(suggested_addresses: [])
  end

  # # #

  @address_data EpicenterWeb.Styleguide.AutocompleteData.generate_address_data()

  defp suggest_address(""), do: []

  defp suggest_address(address) do
    downcased_address = String.downcase(address)

    @address_data
    |> Enum.filter(fn address -> address |> String.downcase() |> String.contains?(downcased_address) end)
    |> Enum.slice(0..10)
  end
end
