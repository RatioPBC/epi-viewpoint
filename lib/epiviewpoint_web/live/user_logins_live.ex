defmodule EpiViewpointWeb.UserLoginsLive do
  use EpiViewpointWeb, :live_view

  import EpiViewpointWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_admin_user!: 2, ok: 1]

  alias EpiViewpoint.Accounts
  alias EpiViewpointWeb.Format

  def mount(%{"id" => id}, session, socket) do
    user = Accounts.get_user(id)
    logins = Accounts.list_recent_logins(user.id)

    socket
    |> assign_defaults()
    |> authenticate_admin_user!(session)
    |> assign(user: user)
    |> assign(logins: logins)
    |> assign_page_title("Logins for #{user.name}")
    |> ok()
  end

  def operating_system(login) do
    ua = UAParser.parse(login.user_agent)
    to_string(ua.os)
  end

  def browser(login) do
    ua = UAParser.parse(login.user_agent)
    to_string(ua)
  end

  def format_date(date), do: date |> Format.date_time_with_presented_time_zone()
end
