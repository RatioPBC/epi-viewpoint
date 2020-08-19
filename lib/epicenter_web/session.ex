defmodule EpicenterWeb.Session do
  alias Epicenter.Cases.Import.ImportInfo
  alias Plug.Conn

  def last_csv_import_info(conn), do: Conn.get_session(conn, :last_csv_import_info)
  def put_last_csv_import_info(conn, %ImportInfo{} = import_info), do: Conn.put_session(conn, :last_csv_import_info, import_info)
end
