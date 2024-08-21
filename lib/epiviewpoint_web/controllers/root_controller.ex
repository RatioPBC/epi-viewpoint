defmodule EpiViewpointWeb.RootController do
  use EpiViewpointWeb, :controller

  def show(conn, _params) do
    conn |> redirect(to: ~p"/people")
  end
end
