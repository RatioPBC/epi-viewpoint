defmodule EpiViewpointWeb.UserAuthTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Accounts.UserToken
  alias EpiViewpoint.AccountsFixtures
  alias EpiViewpoint.Repo
  alias EpiViewpointWeb.UserAuth
  alias Plug.Conn
  alias Phoenix.Flash

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, EpiViewpointWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    user = AccountsFixtures.user_fixture()

    %{user: user, conn: conn}
  end

  describe "log_in_user/3" do
    test "stores the user token in the session", %{conn: conn, user: user} do
      conn = UserAuth.log_in_user(conn, user)
      assert token = get_session(conn, :user_token)
      assert get_session(conn, :live_socket_id) == "users_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Accounts.get_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, user: user} do
      conn = conn |> put_session(:to_be_removed, "value") |> UserAuth.log_in_user(user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, user: user} do
      conn = conn |> put_session(:user_return_to, "/hello") |> UserAuth.log_in_user(user)
      assert redirected_to(conn) == "/hello"
    end

    test "creates login record", %{conn: conn, user: user} do
      conn = Plug.Conn.put_req_header(conn, "user-agent", "foobar")

      assert_that UserAuth.log_in_user(conn, user),
        changes: length(Accounts.list_recent_logins(user.id)),
        from: 0,
        to: 1

      [login] = Accounts.list_recent_logins(user.id)
      assert login.user_agent == "foobar"
    end
  end

  describe "logout_user/1" do
    test "erases session and cookies", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user) |> Map.get(:token)

      conn =
        conn
        |> put_session(:user_token, token)
        |> fetch_cookies()
        |> UserAuth.log_out_user()

      refute get_session(conn, :user_token)
      assert redirected_to(conn) == "/"
      refute Accounts.get_user_by_session_token(token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "users_sessions:abcdef-token"
      EpiViewpointWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> UserAuth.log_out_user()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "users_sessions:abcdef-token"
      }
    end

    test "works even if user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> UserAuth.log_out_user()
      refute get_session(conn, :user_token)
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_user/2" do
    test "authenticates user from session", %{conn: conn, user: user} do
      token = Accounts.generate_user_session_token(user) |> Map.get(:token)
      conn = conn |> put_session(:user_token, token) |> UserAuth.fetch_current_user([])
      assert conn.assigns.current_user.id == user.id
    end

    test "does not authenticate if data is missing", %{conn: conn, user: user} do
      _ = Accounts.generate_user_session_token(user)
      conn = UserAuth.fetch_current_user(conn, [])
      refute get_session(conn, :user_token)
      refute conn.assigns.current_user
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects if user is half-authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_user, user)
        |> EpiViewpointWeb.Session.put_multifactor_auth_success(false)
        |> UserAuth.redirect_if_user_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "redirects if user is authenticated", %{conn: conn, user: user} do
      expires_at = NaiveDateTime.utc_now() |> NaiveDateTime.add(100, :second) |> NaiveDateTime.truncate(:second)

      conn =
        conn
        |> setup_user_token(user, expires_at)
        |> assign(:current_user, user)
        |> EpiViewpointWeb.Session.put_multifactor_auth_success(true)
        |> UserAuth.redirect_if_user_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if user is not authenticated", %{conn: conn} do
      conn = UserAuth.redirect_if_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_admin/2" do
    test "shows a forbidden error if the user is NOT authenticated as an admin", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_user, user)
        |> UserAuth.require_admin([])

      assert conn.halted
      assert text_response(conn, 403) == "Forbidden"
    end

    test "allows the user to continue if they are an admin", %{conn: conn, user: user} do
      {:ok, admin} = user |> Accounts.update_user(%{admin: true}, EpiViewpoint.Test.Fixtures.admin_audit_meta())

      conn =
        conn
        |> assign(:current_user, admin)
        |> UserAuth.require_admin([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_user/2" do
    test "redirects if user is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> UserAuth.require_authenticated_user([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/users/login"
      assert Flash.get(conn.assigns.flash, :error) == "You must log in to access this page"
    end

    test "redirects if user is authenticated but not confirmed", %{conn: conn} do
      user = AccountsFixtures.unconfirmed_user_fixture(%{tid: "user2"})
      conn = conn |> fetch_flash() |> assign(:current_user, user) |> UserAuth.require_authenticated_user([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/users/login"
      assert Flash.get(conn.assigns.flash, :error) == "The account you logged into has not yet been activated"
    end

    test "redirects if the user is authenticated and confirmed but does not have mfa set up", %{conn: conn} do
      user = AccountsFixtures.single_factor_user_fixture(%{tid: "user2"})
      conn = conn |> fetch_flash() |> assign(:current_user, user) |> UserAuth.require_authenticated_user([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/users/mfa-setup"
    end

    test "redirects if user is authenticated but disabled", %{conn: conn, user: user} do
      {:ok, user} = Accounts.update_user(user, %{disabled: true}, EpiViewpoint.Test.Fixtures.admin_audit_meta())
      conn = conn |> fetch_flash() |> assign(:current_user, user) |> UserAuth.require_authenticated_user([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/users/login"
      assert Flash.get(conn.assigns.flash, :error) == "Your account has been disabled by an administrator"
    end

    test "redirects if user is authenticated but the token expired", %{conn: conn, user: user} do
      expires_at = NaiveDateTime.utc_now() |> NaiveDateTime.add(-1, :second) |> NaiveDateTime.truncate(:second)

      conn =
        conn
        |> setup_user_token(user, expires_at)
        |> fetch_flash()
        |> assign(:current_user, user)
        |> EpiViewpointWeb.Session.put_multifactor_auth_success(true)

      conn = conn |> UserAuth.require_authenticated_user([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/users/login"
      assert Flash.get(conn.assigns.flash, :error) == "Your session has expired. Please log in again."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | request_path: "/foo", query_string: ""}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo"

      halted_conn =
        %{conn | request_path: "/foo", query_string: "bar=baz"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | request_path: "/foo?bar", method: "POST"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      refute get_session(halted_conn, :user_return_to)
    end

    test "does redirect if user is half-authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> fetch_flash()
        |> assign(:current_user, user)
        |> EpiViewpointWeb.Session.put_multifactor_auth_success(false)
        |> UserAuth.require_authenticated_user([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/users/mfa"
    end

    test "does not redirect if user is authenticated", %{conn: conn, user: user} do
      expires_at = NaiveDateTime.utc_now() |> NaiveDateTime.add(100, :second) |> NaiveDateTime.truncate(:second)

      conn =
        conn
        |> setup_user_token(user, expires_at)
        |> fetch_flash()
        |> assign(:current_user, user)
        |> EpiViewpointWeb.Session.put_multifactor_auth_success(true)
        |> UserAuth.require_authenticated_user([])

      refute conn.halted
      refute conn.status
    end
  end

  defp setup_user_token(conn, user, expires_at) do
    token_string = Accounts.generate_user_session_token(user) |> Map.get(:token)
    user_token = UserToken.fetch_user_token_query(token_string) |> Repo.one() |> UserToken.changeset(%{expires_at: expires_at}) |> Repo.update!()
    conn |> Conn.merge_private(plug_session: %{"user_token" => user_token.token})
  end
end
