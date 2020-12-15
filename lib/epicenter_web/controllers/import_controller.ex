defmodule EpicenterWeb.ImportController do
  @moduledoc """
  LiveView doesn't currently support file uploads, so this is a regular controller. It could probably be enhanced
  with some ajax or something.
  """

  use EpicenterWeb, :controller

  alias Epicenter.Cases
  alias EpicenterWeb.Session
  alias EpicenterWeb.UploadedFile
  alias Epicenter.DateParsingError

  @common_assigns [page_title: "Import labs"]

  def create(%{assigns: %{current_user: %{admin: false}}} = conn, _file) do
    redirect(conn, to: "/")
  end

  def create(conn, %{"file" => plug_upload}) do
    result = UploadedFile.from_plug_upload(plug_upload) |> Cases.import_lab_results(conn.assigns.current_user)

    case result do
      {:ok, import_info} ->
        {_imported_people, popped_import_info} = import_info |> Map.pop(:imported_people)

        conn
        |> Session.set_last_csv_import_info(popped_import_info)
        |> redirect(to: Routes.import_path(conn, :show))

      {:error, [user_readable: user_readable_message]} ->
        conn
        |> Session.set_import_error_message(user_readable_message)
        |> redirect(to: Routes.import_start_path(conn, EpicenterWeb.ImportLive))

      {:error, %DateParsingError{user_readable: user_readable_message}} ->
        conn
        |> Session.set_import_error_message(user_readable_message)
        |> redirect(to: Routes.import_start_path(conn, EpicenterWeb.ImportLive))
    end
  end

  def show(conn, _params) do
    conn |> render_with_common_assigns("show.html", last_csv_import_info: Session.get_last_csv_import_info(conn))
  end

  defp render_with_common_assigns(conn, template, assigns),
    do: render(conn, template, Keyword.merge(@common_assigns, assigns))
end
