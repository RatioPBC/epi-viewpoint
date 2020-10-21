defmodule EpicenterWeb.UsersLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_admin_defaults: 2, assign_page_title: 2, ok: 1]

  alias Epicenter.Accounts
  alias Epicenter.Accounts.User

  def mount(_params, session, socket) do
    socket
    |> assign_admin_defaults(session)
    |> assign_page_title("Users")
    |> assign(users: Accounts.list_users())
    |> ok()
  end

  def active_status(%User{disabled: true}), do: "Inactive"
  def active_status(%User{}), do: "Active"

  def type(%User{admin: true}), do: "Admin"
  def type(%User{}), do: "User"
end
