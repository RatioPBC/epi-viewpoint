defmodule EpicenterWeb.ImportControllerTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Tempfile
  alias EpicenterWeb.Session

  describe "create" do
    test "accepts file upload", %{conn: conn} do
      temp_file_path =
        """
        first_name , last_name , dob        , thing, sample_date , result_date , result   , glorp
        Alice      , Ant       , 01/02/1970 , graz , 06/01/2020  , 06/03/2020  , positive , 393
        Billy      , Bat       , 03/04/1990 , fnord, 06/06/2020  , 06/07/2020  , negative , sn3
        """
        |> Tempfile.write!("csv")

      on_exit(fn -> File.rm!(temp_file_path) end)

      conn = post(conn, Routes.import_path(conn, :create), %{"file" => %Plug.Upload{path: temp_file_path}})

      assert conn |> redirected_to() == "/import/complete"
      assert conn |> Session.last_csv_import_results() == %{people: 2, lab_results: 2}
    end
  end

  describe "show" do
    test "shows the number of items uploaded", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session([])
        |> Session.put_last_csv_import_results(%{people: 2, lab_results: 3})
        |> get(Routes.import_path(conn, :show))

      assert conn |> html_response(200) =~ "Successfully imported 2 people and 3 lab results"
    end
  end
end
