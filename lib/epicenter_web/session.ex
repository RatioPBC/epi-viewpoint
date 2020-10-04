defmodule EpicenterWeb.Session do
  alias Epicenter.Cases.Import.ImportInfo
  alias Plug.Conn

  def append_fake_mail(conn, to, body),
    do: Conn.put_session(conn, :fake_mail, [%{to: to, body: body, sent: NaiveDateTime.utc_now()} | get_fake_mail(conn)])

  def get_fake_mail(conn),
    do: Conn.get_session(conn, :fake_mail) || []

  def get_last_csv_import_info(conn),
    do: Conn.get_session(conn, :last_csv_import_info)

  def set_last_csv_import_info(conn, %ImportInfo{} = import_info),
    do: Conn.put_session(conn, :last_csv_import_info, import_info)

  def ensure_multifactor_auth_secret(conn, if_nil: if_nil_fn) do
    case get_multifactor_auth_secret(conn) do
      nil -> conn |> put_multifactor_auth_secret(if_nil_fn.())
      {_secret, _key} -> conn
    end
  end

  def get_multifactor_auth_secret(conn),
    do: Conn.get_session(conn, :multifactor_auth_secret)

  def put_multifactor_auth_secret(conn, secret_and_key),
    do: Conn.put_session(conn, :multifactor_auth_secret, secret_and_key)
end
