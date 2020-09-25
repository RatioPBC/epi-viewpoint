defmodule Epicenter.Cases.ImportTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [pluck: 2, tids: 1]

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Import
  alias Epicenter.Cases.ImportedFile
  alias Epicenter.Repo
  alias Epicenter.Test

  describe "import_csv" do
    setup do
      [originator: Test.Fixtures.user_attrs("originator") |> Accounts.create_user!()]
    end

    test "creates LabResult records and Person records from csv data", %{originator: originator} do
      assert {:ok,
              %Epicenter.Cases.Import.ImportInfo{
                imported_people: imported_people,
                imported_lab_result_count: 2,
                imported_person_count: 2,
                total_lab_result_count: 2,
                total_person_count: 2
              }} =
               %{
                 file_name: "test.csv",
                 contents: """
                 search_firstname_2 , search_lastname_1 , dateofbirth_8 , phonenumber_7 , caseid_0 , datecollected_36 , resultdate_42 , result_39 , orderingfacilityname_37 , person_tid , lab_result_tid , diagaddress_street1_3 , diagaddress_city_4 , diagaddress_state_5 , diagaddress_zip_6 , datereportedtolhd_44 , testname_38 , person_tid, sex_11, ethnicity_13, occupation_18   , race_12
                 Alice              , Testuser          , 01/01/1970    , 1111111000    , 10000    , 06/01/2020       , 06/03/2020    , positive  , Lab Co South            , alice      , alice-result-1 ,                       ,                    ,                     ,                   , 06/05/2020           , TestTest    , alice     , female, Cuban       , Rocket Scientist, Asian Indian
                 Billy              , Testuser          , 03/01/1990    , 1111111001    , 10001    , 06/06/2020       , 06/07/2020    , negative  ,                         , billy      , billy-result-1 , 1234 Test St          , City               , TS                  , 00000             ,                      ,             , bill      ,       ,             ,                 ,
                 """
               }
               |> Import.import_csv(originator)

      assert imported_people |> tids() == ["alice", "billy"]

      [lab_result_1, lab_result_2] = Cases.list_lab_results()
      assert lab_result_1.result == "positive"
      assert lab_result_1.sampled_on == ~D[2020-06-01]
      assert lab_result_1.analyzed_on == ~D[2020-06-03]
      assert lab_result_1.reported_on == ~D[2020-06-05]
      assert lab_result_1.test_type == "TestTest"
      assert lab_result_1.tid == "alice-result-1"
      assert lab_result_1.request_facility_name == "Lab Co South"

      assert lab_result_2.result == "negative"
      assert lab_result_2.sampled_on == ~D[2020-06-06]
      assert lab_result_2.analyzed_on == ~D[2020-06-07]
      assert lab_result_2.reported_on == nil
      assert lab_result_2.test_type == nil
      assert lab_result_2.tid == "billy-result-1"
      assert lab_result_2.request_facility_name == nil

      [alice, billy] = Cases.list_people() |> Cases.preload_phones() |> Cases.preload_addresses()
      assert alice.dob == ~D[1970-01-01]
      assert alice.external_id == "10000"
      assert alice.first_name == "Alice"
      assert alice.last_name == "Testuser"
      assert alice.phones |> pluck(:number) == [1_111_111_000]
      assert alice.tid == "alice"
      assert alice.sex_at_birth == "female"
      assert alice.ethnicity == "Cuban"
      assert alice.occupation == "Rocket Scientist"
      assert alice.race == "Asian Indian"

      assert_versioned(alice, expected_count: 1)

      assert billy.dob == ~D[1990-03-01]
      assert billy.external_id == "10001"
      assert billy.first_name == "Billy"
      assert billy.last_name == "Testuser"
      assert billy.phones |> pluck(:number) == [1_111_111_001]
      assert billy.tid == "billy"
      assert billy.addresses |> pluck(:full_address) == ["1234 Test St, City, TS 00000"]
      assert_versioned(billy, expected_count: 1)
    end

    test "updates existing phone number when importing a duplicate for the same person", %{originator: originator} do
      alice_attrs = %{first_name: "Alice", last_name: "Testuser", dob: ~D[1970-01-01]}
      {:ok, alice} = Cases.create_person(Test.Fixtures.person_attrs(originator, "alice", alice_attrs))
      Cases.create_phone!(Test.Fixtures.phone_attrs(alice, "0", %{number: 1_111_111_000}))

      %{
        file_name: "test.csv",
        contents: """
        search_firstname_2 , search_lastname_1 , dateofbirth_8 , phonenumber_7 , caseid_0 , datecollected_36 , resultdate_42 , result_39 , orderingfacilityname_37, person_tid , lab_result_tid , diagaddress_street1_3 , diagaddress_city_4 , diagaddress_state_5 , diagaddress_zip_6
        Alice              , Testuser          , 01/01/1970    , 1111111000    , 10000    , 06/01/2020       , 06/03/2020    , positive  , Lab Co South           , alice      , alice-result-1 ,                       ,                    ,                     ,
        """
      }
      |> Import.import_csv(originator)

      assert Cases.count_phones() == 1
    end

    test "updates existing address when importing a duplicate for the same person", %{originator: originator} do
      alice_attrs = %{first_name: "Alice", last_name: "Testuser", dob: ~D[1970-01-01]}
      {:ok, alice} = Cases.create_person(Test.Fixtures.person_attrs(originator, "alice", alice_attrs))
      Cases.create_address!(Test.Fixtures.address_attrs(alice, "0", 4250, %{}))
      assert Cases.count_addresses() == 1

      import_output =
        %{
          file_name: "test.csv",
          contents: """
          search_firstname_2 , search_lastname_1 , dateofbirth_8 , phonenumber_7 , caseid_0 , datecollected_36 , resultdate_42 , result_39 , orderingfacilityname_37, person_tid , lab_result_tid , diagaddress_street1_3       , diagaddress_city_4 , diagaddress_state_5  , diagaddress_zip_6
          Alice              , Testuser          , 01/01/1970    , 1111111000    , 10000    , 06/01/2020       , 06/03/2020    , positive  , Lab Co South           , alice      , alice-result-1 , 4250 Test St                , City               , TS                   , 00000
          """
        }
        |> Import.import_csv(originator)

      assert {:ok, %Epicenter.Cases.Import.ImportInfo{}} = import_output
      assert Cases.count_addresses() == 1
    end

    @tag :skip
    test "maintains pre-existing demographic information when importing another record for the same person", %{originator: originator} do
      alice_attrs = %{
        first_name: "Alice",
        last_name: "Testuser",
        dob: ~D[1970-01-01],
        sex_at_birth: "female",
        race: "Asian Indian",
        occupation: "Rocket Scientist",
        ethnicity: "Cuban"
      }

      {:ok, alice} = Cases.create_person(Test.Fixtures.person_attrs(originator, "alice", alice_attrs))

      import_output =
        %{
          file_name: "test.csv",
          contents: """
          search_firstname_2 , search_lastname_1 , dateofbirth_8 , phonenumber_7 , caseid_0 , datecollected_36 , resultdate_42 , result_39 , orderingfacilityname_37, person_tid , lab_result_tid , sex_11, race_12, occupation_18, ethnicity_13
          Alice              , Testuser          , 01/01/1970    , 1111111000    , 10000    , 06/01/2020       , 06/03/2020    , positive  , Lab Co South           , alice      , alice-result-1 , male  , White  , Brain Surgeon, Puerto Rican
          """
        }
        |> Import.import_csv(originator)

      assert {:ok, %Epicenter.Cases.Import.ImportInfo{}} = import_output
      updated_alice = Cases.get_person(alice.id)
      assert updated_alice.sex_at_birth == "female"
      assert updated_alice.race == "Asian Indian"
      assert updated_alice.occupation == "Rocket Scientist"
      assert updated_alice.ethnicity == "Cuban"
    end

    @tag :skip
    test "fills missing demographic information when importing another record for the same person", %{originator: originator} do
      alice_attrs = %{first_name: "Alice", last_name: "Testuser", dob: ~D[1970-01-01]}
      {:ok, alice} = Cases.create_person(Test.Fixtures.person_attrs(originator, "alice", alice_attrs))

      import_output =
        %{
          file_name: "test.csv",
          contents: """
          search_firstname_2 , search_lastname_1 , dateofbirth_8 , phonenumber_7 , caseid_0 , datecollected_36 , resultdate_42 , result_39 , orderingfacilityname_37, person_tid , lab_result_tid , sex_11, race_12, occupation_18, ethnicity_13
          Alice              , Testuser          , 01/01/1970    , 1111111000    , 10000    , 06/01/2020       , 06/03/2020    , positive  , Lab Co South           , alice      , alice-result-1 , male  , White  , Brain Surgeon, Puerto Rican
          """
        }
        |> Import.import_csv(originator)

      assert {:ok, %Epicenter.Cases.Import.ImportInfo{}} = import_output
      updated_alice = Cases.get_person(alice.id)
      assert updated_alice.sex_at_birth == "male"
      assert updated_alice.race == "White"
      assert updated_alice.occupation == "Brain Surgeon"
      assert updated_alice.ethnicity == "Puerto Rican"
    end

    test "saves an ImportedFile record for the imported CSV", %{originator: originator} do
      in_file_attrs = %{
        file_name: "test_file.csv",
        contents: """
        search_firstname_2 , search_lastname_1 , dateofbirth_8 , phonenumber_7 , caseid_0 , datecollected_36 , resultdate_42 , result_39 , person_tid , lab_result_tid , diagaddress_street1_3 , diagaddress_city_4 , diagaddress_state_5 , diagaddress_zip_6
        Alice              , Testuser          , 01/01/1970    , 1111111000    , 10000    , 06/01/2020       , 06/03/2020    , positive  , alice      , alice-result-1 ,                       ,                    ,                     ,
        Billy              , Testuser          , 03/01/1990    , 1111111001    , 10001    , 06/06/2020       , 06/07/2020    , negative  , billy      , billy-result-1 , 1234 Test St          , City               , TS                  , 00000
        """
      }

      {:ok, _} = Import.import_csv(in_file_attrs, originator)
      assert ImportedFile |> Repo.all() |> Enum.count() == 1
      assert in_file_attrs == Repo.one(ImportedFile) |> Map.take([:file_name, :contents])
    end

    test "returns an error if the file is missing required values (file_name or contents)", %{originator: originator} do
      in_file_attrs = %{
        file_name: "",
        contents: """
        search_firstname_2 , search_lastname_1 , dateofbirth_8 , phonenumber_7 , caseid_0 , datecollected_36 , resultdate_42 , result_39 , person_tid , lab_result_tid , diagaddress_street1_3 , diagaddress_city_4 , diagaddress_state_5 , diagaddress_zip_6
        Alice              , Testuser          , 01/01/1970    , 1111111000    , 10000    , 06/01/2020       , 06/03/2020    , positive  , alice      , alice-result-1 ,                       ,                    ,                     ,
        Billy              , Testuser          , 03/01/1990    , 1111111001    , 10001    , 06/06/2020       , 06/07/2020    , negative  , billy      , billy-result-1 , 1234 Test St          , City               , TS                  , 00000
        """
      }

      assert {:error, %Ecto.InvalidChangesetError{changeset: %{errors: [file_name: _]}}} = Import.import_csv(in_file_attrs, originator)
    end

    test "if two lab results have the same first_name, last_name, and dob, they are considered the same person", %{originator: originator} do
      assert {:ok,
              %Epicenter.Cases.Import.ImportInfo{
                imported_people: imported_people,
                imported_lab_result_count: 4,
                imported_person_count: 3,
                total_lab_result_count: 4,
                total_person_count: 3
              }} =
               %{
                 file_name: "test.csv",
                 contents: """
                 search_firstname_2 , search_lastname_1 , dateofbirth_8 , datecollected_36 , resultdate_42 , result_39 , person_tid , lab_result_tid
                 Alice              , Testuser          , 01/01/1970    , 06/01/2020       , 06/02/2020    , positive  , alice      , alice-result
                 Billy              , Testuser          , 01/01/1990    , 07/01/2020       , 07/02/2020    , negative  , billy-1    , billy-1-older-result
                 Billy              , Testuser          , 01/01/1990    , 08/01/2020       , 08/02/2020    , positive  , billy-1    , billy-1-newer-result
                 Billy              , Testuser          , 01/01/2000    , 09/01/2020       , 09/02/2020    , positive  , billy-2    , billy-2-result
                 """
               }
               |> Import.import_csv(originator)

      assert imported_people |> tids() == ["alice", "billy-2", "billy-1"]
      [alice, billy_2, billy_1] = Cases.list_people(:all) |> Enum.map(&Cases.preload_lab_results/1)
      assert alice.tid == "alice"
      assert alice.lab_results |> tids() == ~w{alice-result}
      assert billy_1.lab_results |> tids() == ~w{billy-1-newer-result billy-1-older-result}
      assert billy_2.lab_results |> tids() == ~w{billy-2-result}
    end

    test "does not create any resource if it blows up AFTER creating a row", %{originator: originator} do
      # NOTE:
      # To test the rollback behavior we must test that at least one successful call to
      # add a row is made before the exception happens.
      # It is important that this import fails due to a DB constraint violation and not due to
      # a csv parsing violation. csv parsing happens completely before any rows are added,
      # which renders  verifying that no rows are added uninformative.

      result =
        %{
          file_name: "test.csv",
          contents: """
          search_firstname_2 , search_lastname_1 , dateofbirth_8 , datecollected_36 , resultdate_42 , result_39 , person_tid , lab_result_tid
          Alice              , Testuser          , 01/01/1970    , 06/01/2020       , 06/02/2020    , positive  , alice      , alice-result
                             ,                   , 01/02/1980    ,                  ,               ,           ,            ,
          """
        }
        |> Import.import_csv(originator)

      assert {:error, %Ecto.InvalidChangesetError{}} = result

      assert Cases.count_people() == 0
      assert Cases.count_lab_results() == 0
      assert Cases.count_phones() == 0
    end

    test "returns an error message if the CSV is missing columns", %{originator: originator} do
      result =
        %{
          file_name: "test.csv",
          contents: "missing columns"
        }
        |> Import.import_csv(originator)

      error_message = "Missing required columns: datecollected_36, dateofbirth_8, result_39, resultdate_42, search_firstname_2, search_lastname_1"
      assert {:error, error_message} == result
    end

    test "returns an error message when the CSV is poorly formatted", %{originator: originator} do
      {:error, message} =
        %{
          file_name: "test.csv",
          contents: """
          search_firstname_2 , search_lastname_1 , dateofbirth_8 , datecollected_36 , resultdate_42 , result_39 , person_tid , lab_result_tid
          \"Alice\"          , Testuser          , 01/01/1970    , 06/01/2020       , 06/02/2020    , positive  , alice      , alice-result
          """
        }
        |> Import.import_csv(originator)

      assert message =~ "unexpected escape character"
    end

    test "can successfully import sample_data/lab_results.csv", %{originator: originator} do
      file_name = "sample_data/lab_results.csv"

      assert {:ok,
              %Epicenter.Cases.Import.ImportInfo{
                imported_lab_result_count: 31,
                imported_person_count: 26,
                total_lab_result_count: 31,
                total_person_count: 26
              }} = %{file_name: file_name, contents: File.read!(file_name)} |> Import.import_csv(originator)
    end
  end
end
