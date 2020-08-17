defmodule EpicenterWeb.Session do
  alias Plug.Conn

  def last_csv_import_results(conn), do: Conn.get_session(conn, :last_csv_import_results)
  def put_last_csv_import_results(conn, length), do: Conn.put_session(conn, :last_csv_import_results, length)
end
