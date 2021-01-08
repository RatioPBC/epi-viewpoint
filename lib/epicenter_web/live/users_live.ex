defmodule EpicenterWeb.UsersLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_admin_user!: 2, noreply: 1, ok: 1]

  alias Epicenter.Accounts
  alias Epicenter.Accounts.User
  alias EpicenterWeb.Endpoint

  defmodule UserDetails do
    defstruct ~w{active_status email id name password_reset_url tid type}a

    def new(%User{} = user) do
      %UserDetails{
        active_status: if(user.disabled, do: "Inactive", else: "Active"),
        email: user.email,
        id: user.id,
        name: user.name,
        password_reset_url: nil,
        tid: user.tid,
        type: if(user.admin, do: "Admin", else: "Member")
      }
    end
  end

  def mount(_params, session, socket) do
    socket
    |> assign_defaults()
    |> authenticate_admin_user!(session)
    |> assign_page_title("Users")
    |> assign(users: Accounts.list_users() |> Enum.map(&UserDetails.new/1))
    |> ok()
  end

  def handle_event("reset-password", %{"user-id" => user_id}, socket),
    do: socket |> assign(users: set_password_reset_url(socket.assigns.users, user_id, &password_reset_url/1)) |> noreply()

  def handle_event("close-reset-password", %{"user-id" => user_id}, socket),
    do: socket |> assign(users: set_password_reset_url(socket.assigns.users, user_id, fn _ -> nil end)) |> noreply()

  defp set_password_reset_url(users, user_id, url_fn) do
    Enum.map(users, fn
      %{id: ^user_id} = user -> %{user | password_reset_url: url_fn.(user)}
      user -> user
    end)
  end

  defp password_reset_url(user) do
    {:ok, token} = Accounts.generate_user_reset_password_token(user)
    Routes.user_reset_password_url(Endpoint, :edit, token)
  end
end
