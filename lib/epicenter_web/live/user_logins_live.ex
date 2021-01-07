defmodule EpicenterWeb.UserLoginsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_admin_user!: 2, ok: 1]

  alias Epicenter.Accounts
  alias EpicenterWeb.Format
  alias EpicenterWeb.PresentationConstants

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

  def operating_system(login) do
    ua = UAParser.parse(login.user_agent)
    to_string(ua.os)
  end

  def browser(login) do
    ua = UAParser.parse(login.user_agent)
    to_string(ua)
  end

  def format_date(date),
    do: date |> convert_to_presented_time_zone() |> Format.date_time_with_zone()

  defp convert_to_presented_time_zone(datetime),
    do: DateTime.shift_zone!(datetime, PresentationConstants.presented_time_zone())
end
