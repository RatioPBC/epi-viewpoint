defmodule EpiViewpointWeb.HealthCheckIntegrationTest do
  use EpiViewpointWeb.IntegrationCase, async: true

  import Mox
  setup :verify_on_exit!

  alias EpiViewpoint.Test

  test "successful healthcheck", %{conn: conn} do
    Test.HealthCheckMock |> expect(:database, fn -> {:ok, :anything} end)

    conn
    |> get(~p"/healthcheck")
    |> assert_response(status: 200)
  end

  test "unsuccessful healthcheck", %{conn: conn} do
    Test.HealthCheckMock |> expect(:database, fn -> {:error, :anything} end)

    conn
    |> get(~p"/healthcheck")
    |> assert_response(status: 500)
  end
end
