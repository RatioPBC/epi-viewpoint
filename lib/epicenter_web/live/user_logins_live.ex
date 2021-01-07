defmodule EpicenterWeb.UserLoginsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_admin_user!: 2, ok: 1]

  alias Epicenter.Accounts

  def mount(%{"id" => id}, session, socket) do
    user = Accounts.get_user(id)
    logins = Accounts.list_logins(user.id)

    socket
    |> assign_defaults()
    |> authenticate_admin_user!(session)
    |> assign(user: user)
    |> assign(logins: logins)
    |> assign_page_title("Logins for #{user.name}")
    |> ok()
  end
end
