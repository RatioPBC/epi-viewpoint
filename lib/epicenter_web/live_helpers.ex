defmodule EpicenterWeb.LiveHelpers do
  import Phoenix.LiveView

  alias Epicenter.Accounts
  alias EpicenterWeb.Endpoint
  alias EpicenterWeb.Router.Helpers, as: Routes

  def assign_defaults(socket, %{"user_token" => user_token} = _session),
    do: socket |> assign_new(:current_user, fn -> Accounts.get_user_by_session_token(user_token) end) |> check_user()

  def assign_defaults(socket, _session),
    do: socket

  def assign_page_title(socket, page_title),
    do: socket |> assign(page_title: page_title)

  def ok(socket),
    do: {:ok, socket}

  def noreply(socket),
    do: {:noreply, socket}

  # # #

  defp check_user(%{assigns: %{current_user: %{confirmed_at: confirmed_at}}} = socket) when not is_nil(confirmed_at),
    do: socket

  defp check_user(socket),
    do: redirect(socket, to: Routes.user_session_path(Endpoint, :new))
end
