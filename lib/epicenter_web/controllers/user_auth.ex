defmodule EpicenterWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Epicenter.Accounts
  alias EpicenterWeb.Session
  alias EpicenterWeb.Router.Helpers, as: Routes

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
  def log_in_user(conn, user, _params \\ %{}) do
    user_token = Accounts.generate_user_session_token(user)

    user_return_to = get_session(conn, :user_return_to)
    mfa_path = user.mfa_secret == nil && Routes.user_multifactor_auth_setup_path(conn, :new)

    user_agent = get_req_header(conn, "user-agent") |> Euclid.Extra.List.first("user_agent_not_found")

    {:ok, _} = Accounts.create_login(%{session_id: user_token.id, user_agent: user_agent, user_id: user.id})

    conn
    |> renew_session()
    |> put_session(:user_token, user_token.token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(user_token.token)}")
    |> redirect(to: mfa_path || user_return_to || signed_in_path(conn))
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
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the user by looking into the session
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token),
      do: {user_token, conn},
      else: {nil, conn}
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

  def require_admin(conn, _opts) do
    cond do
      conn.assigns[:current_user].admin ->
        conn

      true ->
        conn
        |> put_status(:forbidden)
        |> text("Forbidden")
        |> halt()
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
        :authenticated ->
          nil

        :not_logged_in ->
          {"You must log in to access this page", login_path}

        :disabled ->
          {"Your account has been disabled by an administrator", login_path}

        :not_confirmed ->
          {"The account you logged into has not yet been activated", login_path}

        :no_mfa ->
          {"You must have multi-factor authentication set up before you can continue", mfa_setup_path}

        :needs_second_factor ->
          :needs_second_factor

        :expired ->
          {"Your session has expired. Please log in again.", login_path}
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
      conn.assigns[:current_user] == nil ->
        :not_logged_in

      conn.assigns[:current_user].confirmed_at == nil ->
        :not_confirmed

      conn.assigns[:current_user].disabled ->
        :disabled

      mfa_required? && conn.assigns[:current_user].mfa_secret == nil ->
        :no_mfa

      mfa_required? && !Session.multifactor_auth_success?(conn) ->
        :needs_second_factor

      Accounts.session_token_status(conn.private.plug_session["user_token"]) == :expired ->
        :expired

      true ->
        :authenticated
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
