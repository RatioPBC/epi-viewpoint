defmodule EpicenterWeb.ImportController do
  @moduledoc """
  LiveView doesn't currently support file uploads, so this is a regular controller. It could probably be enhanced
  with some ajax or something.
  """

  use EpicenterWeb, :controller

  alias Epicenter.Csv
  alias EpicenterWeb.Session

  def create(conn, %{"file" => %Plug.Upload{path: path}}) do
    length = path |> File.read!() |> Csv.read() |> length()

    conn
    |> Session.put_last_csv_import_length(length)
    |> redirect(to: Routes.import_path(conn, :show))
  end

  def show(conn, _params) do
    conn |> render(last_import_length: Session.last_csv_import_length(conn))
  end
end
