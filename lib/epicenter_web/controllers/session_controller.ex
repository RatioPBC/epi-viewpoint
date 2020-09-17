defmodule EpicenterWeb.SessionController do
  use EpicenterWeb, :controller

  @doc "At some point, this will handle login but for now, just redirect to /people"
  def new(conn, _params) do
    conn |> redirect(to: Routes.people_path(conn, EpicenterWeb.PeopleLive))
  end
end
