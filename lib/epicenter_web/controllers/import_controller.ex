defmodule EpicenterWeb.ImportController do
  @moduledoc """
  LiveView doesn't currently support file uploads, so this is a regular controller. It could probably be enhanced
  with some ajax or something.
  """

  use EpicenterWeb, :controller

  alias Epicenter.Cases
  alias EpicenterWeb.Session

  @common_assigns [page_title: "Import labs"]

  def create(conn, %{"file" => %Plug.Upload{path: path, filename: file_name}}) do
    {:ok, import_info} = %{file_name: file_name, contents: File.read!(path)} |> Cases.import_lab_results(conn.assigns.current_user)

    {imported_people, popped_import_info} = import_info |> Map.pop(:imported_people)
    Cases.broadcast_people(imported_people)

    conn
    |> Session.set_last_csv_import_info(popped_import_info)
    |> redirect(to: Routes.import_path(conn, :show))
  end

  def show(conn, _params) do
    conn |> render_with_common_assigns("show.html", last_csv_import_info: Session.get_last_csv_import_info(conn))
  end

  defp render_with_common_assigns(conn, template, assigns),
    do: render(conn, template, Keyword.merge(@common_assigns, assigns))
end
