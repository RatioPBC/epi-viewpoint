defmodule EpicenterWeb.ConnCase do
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
  by setting `use EpicenterWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Epicenter.Test.ChangesetAssertions
      import EpicenterWeb.ConnCase
      import EpicenterWeb.Test.LiveViewAssertions
      import Euclid.Test.Extra.Assertions

      alias EpicenterWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint EpicenterWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Epicenter.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Epicenter.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  setup do
    {:ok, _} = Epicenter.Test.Fixtures.admin() |> Epicenter.Accounts.change_user(%{}) |> Epicenter.Repo.insert()
    :ok
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Epicenter.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user, opts \\ []) do
    token = Epicenter.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
    |> EpicenterWeb.Session.put_multifactor_auth_success(Keyword.get(opts, :second_factor_authenticated, true))
  end
end
