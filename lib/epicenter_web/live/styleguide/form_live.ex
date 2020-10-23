defmodule EpicenterWeb.Styleguide.FormLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, ok: 1]
  import EpicenterWeb.IconView

  defmodule StyleguideSchema do
    use Ecto.Schema

    embedded_schema do
      field :call_reason, :string
      field :call_time, :string
      field :call_time_daypart, :string
      field :email, :string
      field :first_name, :string
      field :full_address, :string
      field :last_name, :string
    end
  end

  def mount(_params, _session, socket) do
    socket
    |> assign_page_title("Styleguide: multi-field form")
    |> assign(show_nav: false)
    |> assign_changeset()
    |> ok()
  end

  # # #

  defp assign_changeset(socket) do
    changeset =
      %StyleguideSchema{}
      |> Ecto.Changeset.change(%{first_name: "Alice", last_name: "Ant"})
      |> Ecto.Changeset.validate_required([:email])

    socket |> assign(changeset: %{changeset | action: :insert})
  end
end
