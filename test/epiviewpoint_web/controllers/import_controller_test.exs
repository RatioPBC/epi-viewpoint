defmodule EpiViewpointWeb.ImportControllerTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases.Import.ImportInfo
  alias EpiViewpoint.Tempfile
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Session

  setup :log_in_admin
  @admin Test.Fixtures.admin()

  describe "create" do
    @describetag :tmp_dir
    
    test "prevents non-admins from uploading", %{conn: conn, user: user, tmp_dir: tmp_dir} do
      Accounts.update_user(user, %{admin: false}, Test.Fixtures.audit_meta(@admin))

      temp_file_path =
        """
        search_firstname_2 , search_lastname_1 , dateofbirth_8 , datecollected_36 , resultdate_42 , datereportedtolhd_44 , result_39 , glorp , person_tid
        Alice              , Testuser          , 01/01/1970    , 06/02/2020       , 06/01/2020    , 06/03/2020           , positive  , 393   , alice
        Billy              , Testuser          , 03/01/1990    , 06/05/2020       , 06/06/2020    , 06/07/2020           , negative  , sn3   , billy
        """
        |> Tempfile.write_csv!(tmp_dir)

      conn = post(conn, ~p"/import/upload", %{"file" => %Plug.Upload{path: temp_file_path, filename: "test.csv"}})

      assert conn |> redirected_to() == "/"

      refute Session.get_last_file_import_info(conn)
    end

    test "accepts file upload", %{conn: conn, tmp_dir: tmp_dir} do
      temp_file_path =
        """
        search_firstname_2 , search_lastname_1 , dateofbirth_8 , datecollected_36 , resultdate_42 , datereportedtolhd_44 , result_39 , glorp , person_tid
        Alice              , Testuser          , 01/01/1970    , 06/02/2020       , 06/01/2020    , 06/03/2020           , positive  , 393   , alice
        Billy              , Testuser          , 03/01/1990    , 06/05/2020       , 06/06/2020    , 06/07/2020           , negative  , sn3   , billy
        """
        |> Tempfile.write_csv!(tmp_dir)

      conn = post(conn, ~p"/import/upload", %{"file" => %Plug.Upload{path: temp_file_path, filename: "test.csv"}})

      assert conn |> redirected_to() == "/import/complete"

      assert %EpiViewpoint.Cases.Import.ImportInfo{
               imported_lab_result_count: 2,
               imported_person_count: 2,
               total_lab_result_count: 2,
               total_person_count: 2
             } = Session.get_last_file_import_info(conn)
    end

    test "when a required column header is missing", %{conn: conn, tmp_dir: tmp_dir} do
      # remove the dob column
      temp_file_path =
        """
        search_firstname_2 , search_lastname_1 , datecollected_36 , resultdate_42 , datereportedtolhd_44 , result_39 , glorp , person_tid
        Alice              , Testuser          , 06/02/2020       , 06/01/2020    , 06/03/2020           , positive  , 393   , alice
        """
        |> Tempfile.write_csv!(tmp_dir)

      conn = post(conn, ~p"/import/upload", %{"file" => %Plug.Upload{path: temp_file_path, filename: "test.csv"}})

      assert conn |> redirected_to() == "/import/start"
      assert "Missing required fields: dateofbirth_xx" = Session.get_import_error_message(conn)
    end

    test "when a date is poorly formatted", %{conn: conn, tmp_dir: tmp_dir} do
      # date collected has a bad year 06/02/bb
      temp_file_path =
        """
        search_firstname_2 , search_lastname_1 , dateofbirth_8 , datecollected_36 , resultdate_42 , datereportedtolhd_44 , result_39 , glorp , person_tid
        Alice              , Testuser          , 01/01/1970    , 06/02/bb         , 06/01/2020    , 06/03/2020           , positive  , 393   , alice
        """
        |> Tempfile.write_csv!(tmp_dir)

      conn = post(conn, ~p"/import/upload", %{"file" => %Plug.Upload{path: temp_file_path, filename: "test.csv"}})

      assert conn |> redirected_to() == "/import/start"
      assert "Invalid mm-dd-yyyy format: 06/02/bb" = Session.get_import_error_message(conn)
    end

    test "accepts ndjson file upload", %{conn: conn, tmp_dir: tmp_dir} do
      temp_file_path =
        """
        {"search_firstname_2":"Alice","search_lastname_1":"Testuser","dateofbirth_8":"01/01/1970","datecollected_36":"06/02/2020","resultdate_42":"06/01/2020","datereportedtolhd_44":"06/03/2020","result_39":"positive","glorp":"393","person_tid":"alice"}
        {"search_firstname_2":"Billy","search_lastname_1":"Testuser","dateofbirth_8":"03/01/1990","datecollected_36":"06/05/2020","resultdate_42":"06/06/2020","datereportedtolhd_44":"06/07/2020","result_39":"negative","glorp":"sn3","person_tid":"billy"}
        """
        |> Tempfile.write_ndjson!(tmp_dir)

      conn = post(conn, ~p"/import/upload", %{"file" => %Plug.Upload{path: temp_file_path, filename: "test.ndjson"}})

      assert conn |> redirected_to() == "/import/complete"

      assert %EpiViewpoint.Cases.Import.ImportInfo{
               imported_lab_result_count: 2,
               imported_person_count: 2,
               total_lab_result_count: 2,
               total_person_count: 2
             } = Session.get_last_file_import_info(conn)
    end

    test "when a required field is missing in ndjson", %{conn: conn, tmp_dir: tmp_dir} do
      # remove the dateofbirth_8 field
      temp_file_path =
        """
        {"search_firstname_2":"Alice","search_lastname_1":"Testuser","datecollected_36":"06/02/2020","resultdate_42":"06/01/2020","datereportedtolhd_44":"06/03/2020","result_39":"positive","glorp":"393","person_tid":"alice"}
        """
        |> Tempfile.write_ndjson!(tmp_dir)

      conn = post(conn, ~p"/import/upload", %{"file" => %Plug.Upload{path: temp_file_path, filename: "test.ndjson"}})

      assert conn |> redirected_to() == "/import/start"
      assert "Missing required fields: dateofbirth_xx" = Session.get_import_error_message(conn)
    end

    test "when a date is poorly formatted in ndjson", %{conn: conn, tmp_dir: tmp_dir} do
      # date collected has a bad year 06/02/bb
      temp_file_path =
        """
        {"search_firstname_2":"Alice","search_lastname_1":"Testuser","dateofbirth_8":"01/01/1970","datecollected_36":"06/02/bb","resultdate_42":"06/01/2020","datereportedtolhd_44":"06/03/2020","result_39":"positive","glorp":"393","person_tid":"alice"}
        """
        |> Tempfile.write_ndjson!(tmp_dir)

      conn = post(conn, ~p"/import/upload", %{"file" => %Plug.Upload{path: temp_file_path, filename: "test.ndjson"}})

      assert conn |> redirected_to() == "/import/start"
      assert "Invalid mm-dd-yyyy format: 06/02/bb" = Session.get_import_error_message(conn)
    end
  end

  describe "show" do
    test "shows the number of items uploaded", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session([])
        |> Session.set_last_file_import_info(%ImportInfo{
          imported_person_count: 2,
          imported_lab_result_count: 3,
          total_person_count: 50,
          total_lab_result_count: 100
        })
        |> get(~p"/import/complete")

      assert conn |> html_response(200) =~ "Successfully imported 2 people and 3 lab results"
    end
  end
end
