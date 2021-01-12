defmodule EpicenterWeb.Session do
  alias Epicenter.Cases.Import.ImportInfo
  alias Plug.Conn

  def get_last_csv_import_info(conn),
    do: Conn.get_session(conn, :last_csv_import_info)

  def set_last_csv_import_info(conn, %ImportInfo{} = import_info),
    do: conn |> clear_old_messages |> Conn.put_session(:last_csv_import_info, import_info)

  def get_import_error_message(conn),
    do: Conn.get_session(conn, :import_error_message)

  def set_import_error_message(conn, user_readable_message),
    do: conn |> clear_old_messages |> Conn.put_session(:import_error_message, user_readable_message)

  defp clear_old_messages(conn) do
    conn
    |> Conn.delete_session(:import_error_message)
    |> Conn.delete_session(:last_csv_import_info)
  end

  def ensure_multifactor_auth_secret(conn, if_nil: if_nil_fn) do
    case get_multifactor_auth_secret(conn) do
      nil -> conn |> put_multifactor_auth_secret(if_nil_fn.())
      _secret -> conn
    end
  end

  def get_multifactor_auth_secret(conn),
    do: Conn.get_session(conn, :multifactor_auth_secret)

  def put_multifactor_auth_secret(conn, secret),
    do: Conn.put_session(conn, :multifactor_auth_secret, secret)

  def multifactor_auth_success?(conn),
    do: Conn.get_session(conn, :multifactor_auth_success) == true

  def put_multifactor_auth_success(conn, success?),
    do: Conn.put_session(conn, :multifactor_auth_success, success?)
end
