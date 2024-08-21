defmodule EpiViewpointWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use EpiViewpointWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import EpiViewpoint.Test.ChangesetAssertions
      import EpiViewpoint.Test.RevisionAssertions
      import EpiViewpointWeb.ConnCase
      import EpiViewpointWeb.Test.LiveViewAssertions
      import Euclid.Test.Extra.Assertions
      import ExUnit.CaptureLog
      import Phoenix.ConnTest
      import Plug.Conn

      alias EpiViewpoint.Test.AuditLogAssertions
      use Phoenix.VerifiedRoutes, endpoint: EpiViewpointWeb.Endpoint, router: EpiViewpointWeb.Router

      # The default endpoint for testing
      @endpoint EpiViewpointWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EpiViewpoint.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(EpiViewpoint.Repo, {:shared, self()})
    end

    Mox.stub_with(EpiViewpoint.Test.PhiLoggerMock, EpiViewpoint.Test.PhiLoggerStub)

    {:ok, conn: Phoenix.ConnTest.build_conn() |> Plug.Conn.put_req_header("user-agent", "browser")}
  end

  setup do
    {:ok, _} = EpiViewpoint.Test.Fixtures.admin() |> EpiViewpoint.Accounts.change_user(%{}) |> EpiViewpoint.Repo.insert()
    :ok
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = EpiViewpoint.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  def log_in_admin(%{conn: conn}) do
    admin_id = EpiViewpoint.Test.Fixtures.admin().id
    admin = EpiViewpoint.Accounts.get_user(admin_id)
    %{conn: log_in_user(conn, admin), user: admin}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user, opts \\ []) do
    token = EpiViewpoint.Accounts.generate_user_session_token(user) |> Map.get(:token)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
    |> EpiViewpointWeb.Session.put_multifactor_auth_success(Keyword.get(opts, :second_factor_authenticated, true))
  end
end
