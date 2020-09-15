defmodule EpicenterWeb.ImportControllerTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases.Import.ImportInfo
  alias Epicenter.Tempfile
  alias Epicenter.Test
  alias EpicenterWeb.Session

  describe "create" do
    test "accepts file upload", %{conn: conn} do
      temp_file_path =
        """
        first_name , last_name , dob        , thing, sample_date , result_date , result   , glorp
        Alice      , Testuser  , 01/01/1970 , graz , 06/01/2020  , 06/03/2020  , positive , 393
        Billy      , Testuser  , 03/01/1990 , fnord, 06/06/2020  , 06/07/2020  , negative , sn3
        """
        |> Tempfile.write!("csv")

      on_exit(fn -> File.rm!(temp_file_path) end)

      Test.Fixtures.user_attrs("user") |> Accounts.create_user!()

      conn = post(conn, Routes.import_path(conn, :create), %{"file" => %Plug.Upload{path: temp_file_path, filename: "test.csv"}})

      assert conn |> redirected_to() == "/import/complete"

      assert conn |> Session.get_last_csv_import_info() == %Epicenter.Cases.Import.ImportInfo{
               imported_lab_result_count: 2,
               imported_person_count: 2,
               total_lab_result_count: 2,
               total_person_count: 2
             }
    end
  end

  describe "show" do
    test "shows the number of items uploaded", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session([])
        |> Session.set_last_csv_import_info(%ImportInfo{
          imported_person_count: 2,
          imported_lab_result_count: 3,
          total_person_count: 50,
          total_lab_result_count: 100
        })
        |> get(Routes.import_path(conn, :show))

      assert conn |> html_response(200) =~ "Successfully imported 2 people and 3 lab results"
    end
  end
end
