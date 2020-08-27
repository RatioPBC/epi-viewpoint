defmodule EpicenterWeb.Session do
  alias Epicenter.Accounts
  alias Epicenter.Cases.Import.ImportInfo
  alias Plug.Conn

  @doc "Until we have user login, just get the first user from the db"
  def get_current_user(),
    do: Accounts.list_users() |> List.first() || raise("get_current_user() requires at least 1 user in the database")

  def get_last_csv_import_info(conn),
    do: Conn.get_session(conn, :last_csv_import_info)

  def set_last_csv_import_info(conn, %ImportInfo{} = import_info),
    do: Conn.put_session(conn, :last_csv_import_info, import_info)
end
