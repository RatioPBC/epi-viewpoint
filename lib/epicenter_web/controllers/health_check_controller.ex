defmodule EpicenterWeb.HealthCheckController do
  use EpicenterWeb, :controller

  def show(conn, _params) do
    case database_health_check() do
      {:ok, _} -> text(conn, "OK")
      {:error, _} -> conn |> put_status(500) |> text("ERROR: 1")
    end
  end

  defp database_health_check do
    Application.get_env(:epicenter, :health_check).database()
  end
end
