defmodule EpicenterWeb.RootController do
  use EpicenterWeb, :controller

  def show(conn, _params) do
    conn |> redirect(to: ~p"/people")
  end
end
