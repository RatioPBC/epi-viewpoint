defmodule EpicenterWeb.ImportController do
  @moduledoc """
  LiveView doesn't currently support file uploads, so this is a regular controller. It could probably be enhanced
  with some ajax or something.
  """

  use EpicenterWeb, :controller

  alias Epicenter.Cases
  alias EpicenterWeb.Session

  def create(conn, %{"file" => %Plug.Upload{path: path}}) do
    {:ok, results} = path |> File.read!() |> Cases.import_lab_results()

    conn
    |> Session.put_last_csv_import_results(results)
    |> redirect(to: Routes.import_path(conn, :show))
  end

  def show(conn, _params) do
    conn |> render(last_csv_import_results: Session.last_csv_import_results(conn))
  end
end
