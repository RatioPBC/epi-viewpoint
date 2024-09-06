defmodule EpiViewpointWeb.ImportController do
  @moduledoc """
  LiveView doesn't currently support file uploads, so this is a regular controller. It could probably be enhanced
  with some ajax or something.
  """
  use EpiViewpointWeb, :controller

  import EpiViewpointWeb.ControllerHelpers, only: [assign_defaults: 2]

  alias EpiViewpoint.Cases
  alias EpiViewpointWeb.Session
  alias EpiViewpointWeb.UploadedFile
  alias EpiViewpoint.DateParsingError

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
        |> Session.set_last_file_import_info(popped_import_info)
        |> redirect(to: ~p"/import/complete")

      {:error, [user_readable: user_readable_message]} ->
        conn
        |> Session.set_import_error_message(user_readable_message)
        |> redirect(to: ~p"/import/start")

      {:error, %DateParsingError{user_readable: user_readable_message}} ->
        conn
        |> Session.set_import_error_message(user_readable_message)
        |> redirect(to: ~p"/import/start")
    end
  end

  def create_bulk_fhir(conn, %{"files" => plug_uploads}) do

    result = UploadedFile.from_plug_uploads(plug_uploads) |> Cases.import_bulk_fhir_lab_results(conn.assigns.current_user)

    case result do
      {:ok, import_info} ->
        {_imported_people, popped_import_info} = import_info |> Map.pop(:imported_people)

        conn
        |> Session.set_last_file_import_info(popped_import_info)
        |> redirect(to: ~p"/import/complete")

      {:error, [user_readable: user_readable_message]} ->
        conn
        |> Session.set_import_error_message(user_readable_message)
        |> redirect(to: ~p"/import/start")

      {:error, %DateParsingError{user_readable: user_readable_message}} ->
        conn
        |> Session.set_import_error_message(user_readable_message)
        |> redirect(to: ~p"/import/start")
    end

  end


  def show(conn, _params) do
    conn
    |> assign_defaults(@common_assigns)
    |> render("show.html", last_file_import_info: Session.get_last_file_import_info(conn))
  end
end
