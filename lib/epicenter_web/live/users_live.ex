defmodule EpicenterWeb.UsersLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_admin_user!: 2, assign_page_title: 2, ok: 1]

  alias Epicenter.Accounts
  alias Epicenter.Accounts.User

  def mount(_params, session, socket) do
    socket
    |> authenticate_admin_user!(session)
    |> assign_page_title("Users")
    |> assign(users: Accounts.list_users())
    |> ok()
  end

  def active_status(%User{disabled: true}), do: "Inactive"
  def active_status(%User{}), do: "Active"

  def type(%User{admin: true}), do: "Admin"
  def type(%User{}), do: "Member"
end
