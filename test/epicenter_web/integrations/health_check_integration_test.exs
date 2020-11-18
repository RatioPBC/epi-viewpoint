defmodule EpicenterWeb.HealthCheckIntegrationTest do
  use EpicenterWeb.IntegrationCase, async: true

  import Mox
  setup :verify_on_exit!

  alias Epicenter.Test

  test "successful healthcheck", %{conn: conn} do
    Test.HealthCheckMock |> expect(:database, fn -> {:ok, :anything} end)

    conn
    |> get(Routes.health_check_path(conn, :show))
    |> assert_response(status: 200)
  end

  test "unsuccessful healthcheck", %{conn: conn} do
    Test.HealthCheckMock |> expect(:database, fn -> {:error, :anything} end)

    conn
    |> get(Routes.health_check_path(conn, :show))
    |> assert_response(status: 500)
  end
end
