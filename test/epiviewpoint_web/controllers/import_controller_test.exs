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

    test "accepts multiple NDJSON files for bulk FHIR upload", %{conn: conn, tmp_dir: tmp_dir} do
      patient_data = """
      {"resourceType":"Patient","id":"10000","meta":{"profile":["http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"]},"identifier":[{"system":"urn:example:person_tid","value":"alice"}],"name":[{"family":"Testuser","given":["Alice"]}],"birthDate":"1970-01-01","telecom":[{"system":"phone","value":"1111111000"}],"address":[{"line":["1234 Test St"],"city":"City","state":"TS","postalCode":"00000"}],"gender":"female","extension":[{"url":"http://hl7.org/fhir/us/core/StructureDefinition/us-core-race","extension":[{"url":"ombCategory","valueCoding":{"system":"urn:oid:2.16.840.1.113883.6.238","code":"2106-3","display":"White"}},{"url":"text","valueString":"White"}]},{"url":"http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity","extension":[{"url":"ombCategory","valueCoding":{"system":"urn:oid:2.16.840.1.113883.6.238","code":"2186-5","display":"Not Hispanic or Latino"}},{"url":"text","valueString":"Not Hispanic or Latino"}]},{"url":"http://hl7.org/fhir/StructureDefinition/patient-occupation","valueString":"Doctor"}]}
      {"resourceType":"Patient","id":"10004","meta":{"profile":["http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"]},"identifier":[{"system":"urn:example:person_tid","value":"billy"}],"name":[{"family":"Testuser","given":["Billy"]}],"birthDate":"1971-01-01","telecom":[{"system":"phone","value":"1111111004"}],"address":[{"line":["1234 Test St"],"city":"City","state":"TS","postalCode":"00000"}],"gender":"female","extension":[{"url":"http://hl7.org/fhir/us/core/StructureDefinition/us-core-race","extension":[{"url":"ombCategory","valueCoding":{"system":"urn:oid:2.16.840.1.113883.6.238","code":"2106-3","display":"White"}},{"url":"text","valueString":"White"}]},{"url":"http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity","extension":[{"url":"ombCategory","valueCoding":{"system":"urn:oid:2.16.840.1.113883.6.238","code":"2186-5","display":"Not Hispanic or Latino"}},{"url":"text","valueString":"Not Hispanic or Latino"}]},{"url":"http://hl7.org/fhir/StructureDefinition/patient-occupation","valueString":"Doctor"}]}
      """

      observation_data = """
      {"resourceType":"Observation","id":"alice-result-1","meta":{"profile":["http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab"]},"extension":[{"url":"http://hl7.org/fhir/StructureDefinition/datereportedtolhd","valueDate":"08/05/2020"}],"category":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/observation-category","code":"laboratory","display":"Laboratory"}]}],"status":"final","code":{"text":"TestTest"},"subject":{"reference":"Patient/10000"},"effectiveDateTime":"08/01/2020","issued":"2020-08-03T00:00:00Z","performer":[{"reference":"Organization/city-hospital-lab"}],"valueCodeableConcept":{"coding":[{"system":"http://snomed.info/sct","code":"10828004","display":"Positive"}]},"interpretation":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation","code":"POS","display":"Positive"}]}]}
      {"resourceType":"Observation","id":"billy-result-1","meta":{"profile":["http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab"]},"extension":[{"url":"http://hl7.org/fhir/StructureDefinition/datereportedtolhd","valueDate":"08/05/2020"}],"category":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/observation-category","code":"laboratory","display":"Laboratory"}]}],"status":"final","code":{"text":"TestTest"},"subject":{"reference":"Patient/10004"},"effectiveDateTime":"08/02/2020","issued":"2020-08-04T00:00:00Z","performer":[{"reference":"Organization/city-hospital-lab"}],"valueCodeableConcept":{"coding":[{"system":"http://snomed.info/sct","code":"260385009","display":"Negative"}]},"interpretation":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation","code":"NEG","display":"Negative"}]}]}
      """

      organization_data = """
      {"resourceType":"Organization","id":"org1","name":"Lab Co South"}
      {"resourceType":"Organization","id":"org2","name":"City Hospital Lab"}
      """

      patient_file_path = Tempfile.write_ndjson!(patient_data, tmp_dir)
      observation_file_path = Tempfile.write_ndjson!(observation_data, tmp_dir)
      organization_file_path = Tempfile.write_ndjson!(organization_data, tmp_dir)

      conn =
        conn
        |> post(~p"/import/upload_bulk_fhir", %{
          "files" => [
            %Plug.Upload{path: patient_file_path, filename: "Patient.ndjson"},
            %Plug.Upload{path: observation_file_path, filename: "Observation.ndjson"},
            %Plug.Upload{path: organization_file_path, filename: "Organization.ndjson"}
          ]
        })

      assert conn |> redirected_to() == "/import/complete"

      assert %EpiViewpoint.Cases.Import.ImportInfo{
               imported_lab_result_count: 2,
               imported_person_count: 2,
               total_lab_result_count: 2,
               total_person_count: 2
             } = Session.get_last_file_import_info(conn)
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
