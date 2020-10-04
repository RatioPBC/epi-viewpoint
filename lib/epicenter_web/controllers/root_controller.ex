defmodule EpicenterWeb.RootController do
  use EpicenterWeb, :controller

  def show(conn, _params) do
    conn |> redirect(to: Routes.people_path(conn, EpicenterWeb.PeopleLive))
  end
end
