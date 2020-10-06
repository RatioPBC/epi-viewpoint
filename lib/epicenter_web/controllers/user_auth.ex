defmodule EpicenterWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Epicenter.Accounts
  alias EpicenterWeb.Session
  alias EpicenterWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)
    mfa_path = user.mfa_secret == nil && Routes.user_multifactor_auth_setup_path(conn, :new)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: mfa_path || user_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      EpicenterWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, opts) do
    if user_authentication_status(conn, opts) in [:authenticated, :needs_second_factor] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  def require_authenticated_user_without_mfa(conn, _opts) do
    require_authenticated_user(conn, mfa_required?: false)
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, opts) do
    login_path = Routes.user_session_path(conn, :new)
    mfa_setup_path = Routes.user_multifactor_auth_setup_path(conn, :new)
    mfa_path = Routes.user_multifactor_auth_path(conn, :new)

    error =
      case user_authentication_status(conn, opts) do
        :authenticated -> nil
        :not_logged_in -> {"You must log in to access this page", login_path}
        :disabled -> {"Your account has been disabled by an administrator", login_path}
        :not_confirmed -> {"The account you logged into has not yet been activated", login_path}
        :no_mfa -> {"You must have multi-factor authentication set up before you can continue", mfa_setup_path}
        :needs_second_factor -> :needs_second_factor
      end

    case error do
      nil ->
        conn

      :needs_second_factor ->
        conn
        |> redirect(to: mfa_path)
        |> halt()

      {message, redirect_path} ->
        conn
        |> renew_session()
        |> put_flash(:error, message)
        |> maybe_store_return_to()
        |> redirect(to: redirect_path)
        |> halt()
    end
  end

  defp user_authentication_status(conn, opts) do
    mfa_required? = Keyword.get(opts, :mfa_required?, true)

    cond do
      conn.assigns[:current_user] == nil -> :not_logged_in
      conn.assigns[:current_user].confirmed_at == nil -> :not_confirmed
      conn.assigns[:current_user].disabled -> :disabled
      mfa_required? && conn.assigns[:current_user].mfa_secret == nil -> :no_mfa
      mfa_required? && !Session.multifactor_auth_success?(conn) -> :needs_second_factor
      true -> :authenticated
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    %{request_path: request_path, query_string: query_string} = conn
    return_to = if query_string == "", do: request_path, else: request_path <> "?" <> query_string
    put_session(conn, :user_return_to, return_to)
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"
end
