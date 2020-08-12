defmodule EpicenterWeb.Session do
  alias Plug.Conn

  def last_csv_import_length(conn), do: Conn.get_session(conn, :last_import_length)
  def put_last_csv_import_length(conn, length), do: Conn.put_session(conn, :last_import_length, length)
end
