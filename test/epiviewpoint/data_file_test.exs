defmodule EpiViewpoint.DataFileTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpoint.DataFile

  describe "read" do
    test "reads a csv file" do
      """
      first_name , last_name , dob        , thing, sample_date , result_date , result   , glorp
      Alice      , Ant       , 01/02/1970 , graz , 06/01/2020  , 06/03/2020  , positive , 393
      Billy      , Bat       , 03/04/1990 , fnord, 06/06/2020  , 06/07/2020  , negative , sn3
      """
      |> DataFile.read(:csv, &Function.identity/1, required: ~w{first_name last_name dob sample_date result_date result}, optional: ~w{})
      |> assert_eq(
        {:ok,
         [
           %{
             "first_name" => "Alice",
             "last_name" => "Ant",
             "dob" => "01/02/1970",
             "sample_date" => "06/01/2020",
             "result_date" => "06/03/2020",
             "result" => "positive"
           },
           %{
             "first_name" => "Billy",
             "last_name" => "Bat",
             "dob" => "03/04/1990",
             "sample_date" => "06/06/2020",
             "result_date" => "06/07/2020",
             "result" => "negative"
           }
         ]}
      )
    end

    test "ingores unspecified headers" do
      """
      column_a , column_b , column_c
      value_a  , value_b  , value_c
      """
      |> DataFile.read(:csv, &Function.identity/1, required: ~w{column_a}, optional: ~w{column_b})
      |> assert_eq({:ok, [%{"column_a" => "value_a", "column_b" => "value_b"}]})
    end

    test "fails if required header is missing" do
      """
      column_a , column_b
      value_a  , value_b
      """
      |> DataFile.read(:csv, &Function.identity/1, required: ~w{column_a column_b column_c column_d}, optional: ~w{})
      |> assert_eq({:error, :missing_headers, ["column_c", "column_d"]})
    end

    test "allows optional headers" do
      """
      column_a , column_b , optional_c
      value_a  , value_b  , value_c
      """
      |> DataFile.read(:csv, &Function.identity/1, required: ~w{column_a column_b}, optional: ~w{optional_c optional_d})
      |> assert_eq({:ok, [%{"column_a" => "value_a", "column_b" => "value_b", "optional_c" => "value_c"}]})
    end

    test "handles quoted values" do
      """
      column_a   ,"column b", column_c
      "value, a","value b", value c
      """
      |> DataFile.read(:csv, &Function.identity/1, required: ["column_a", "column b", "column_c"], optional: [])
      |> assert_eq({:ok, [%{"column_a" => "value, a", "column b" => "value b", "column_c" => "value c"}]})
    end

    test "handles DOS files (files with BOM as leading character)" do
      optional_columns =
        ~w{datereportedtolhd_0 caseid_1 caseclassificationstatus_2 search_lastname_4 dateofbirth_5 age_6 agetype_7 sex_8 diagaddress_street1_9 diagaddress_city_10 diagaddress_zip_11 diagaddress_state_11 phonenumber_13 dateofdeath_14 race_15 ethnicity_16 testname_17 result_18 reference_19 organism_20 specimentype_21 datecollected_22 resultdate_23 specimenid_24 facilityname_25 address_street_26 address_city_27 address_state_28 orderingfacilityname_30 orderingfacilitycity_31 orderingproviderfirstname_32 orderingproviderlastname_33 orderingprovidercity_34}

      assert {:ok, [%{"search_firstname_3" => "AminaT"}]} =
               File.read!("test/support/fixtures/import_dos_file.csv")
               |> DataFile.read(:csv, &Function.identity/1, required: ["search_firstname_3"], optional: optional_columns)
    end

    test "gives a nicer error message when there are spaces between commas and quotes" do
      expected_message =
        "unexpected escape character \" in \"column_a   , \\\"column b\\\" , column_c\\n\"" <>
          " (make sure there are no spaces between the field separators (commas) and the quotes around field contents)"

      assert {:invalid_csv, ^expected_message} =
               """
               column_a   , "column b" , column_c
               "value, a" , "value b" , value c
               """
               |> DataFile.read(:csv, &Function.identity/1, required: ["column_a", "column b", "column_c"], optional: [])
    end

    test "header transformer transforms headers" do
      """
      first_name , last_name
      Alice      , Ant
      Billy      , Bat
      """
      |> DataFile.read(
        :csv,
        fn headers -> Enum.map(headers, &String.upcase/1) end,
        required: ~w{FIRST_NAME LAST_NAME},
        optional: ~w{}
      )
      |> assert_eq(
        {:ok,
         [
           %{
             "FIRST_NAME" => "Alice",
             "LAST_NAME" => "Ant"
           },
           %{
             "FIRST_NAME" => "Billy",
             "LAST_NAME" => "Bat"
           }
         ]}
      )
    end

    test "reads a ndjson file" do
      """
      {"first_name":"Alice","last_name":"Ant","dob":"01/02/1970","sample_date":"06/01/2020","result_date":"06/03/2020","result":"positive"}
      {"first_name":"Billy","last_name":"Bat","dob":"03/04/1990","sample_date":"06/06/2020","result_date":"06/07/2020","result":"negative"}
      """
      |> DataFile.read(:ndjson, &Function.identity/1, required: ~w{first_name last_name dob sample_date result_date result}, optional: ~w{})
      |> assert_eq(
        {:ok,
         [
           %{
             "first_name" => "Alice",
             "last_name" => "Ant",
             "dob" => "01/02/1970",
             "sample_date" => "06/01/2020",
             "result_date" => "06/03/2020",
             "result" => "positive"
           },
           %{
             "first_name" => "Billy",
             "last_name" => "Bat",
             "dob" => "03/04/1990",
             "sample_date" => "06/06/2020",
             "result_date" => "06/07/2020",
             "result" => "negative"
           }
         ]}
      )
    end

    test "ignores unspecified headers in ndjson" do
      """
      {"column_a":"value_a","column_b":"value_b","column_c":"value_c"}
      """
      |> DataFile.read(:ndjson, &Function.identity/1, required: ~w{column_a}, optional: ~w{column_b})
      |> assert_eq({:ok, [%{"column_a" => "value_a", "column_b" => "value_b"}]})
    end

    test "fails if required header is missing in ndjson" do
      """
      {"column_a":"value_a","column_b":"value_b"}
      """
      |> DataFile.read(:ndjson, &Function.identity/1, required: ~w{column_a column_b column_c column_d}, optional: ~w{})
      |> assert_eq({:error, :missing_headers, ["column_c", "column_d"]})
    end

    test "allows optional headers in ndjson" do
      """
      {"column_a":"value_a","column_b":"value_b","optional_c":"value_c"}
      """
      |> DataFile.read(:ndjson, &Function.identity/1, required: ~w{column_a column_b}, optional: ~w{optional_c optional_d})
      |> assert_eq({:ok, [%{"column_a" => "value_a", "column_b" => "value_b", "optional_c" => "value_c"}]})
    end

    test "header transformer transforms headers in ndjson" do
      """
      {"first_name":"Alice","last_name":"Ant"}
      {"first_name":"Billy","last_name":"Bat"}
      """
      |> DataFile.read(
        :ndjson,
        fn headers -> Enum.map(headers, &String.upcase/1) end,
        required: ~w{FIRST_NAME LAST_NAME},
        optional: ~w{}
      )
      |> assert_eq(
        {:ok,
         [
           %{
             "FIRST_NAME" => "Alice",
             "LAST_NAME" => "Ant"
           },
           %{
             "FIRST_NAME" => "Billy",
             "LAST_NAME" => "Bat"
           }
         ]}
      )
    end

    test "reads a bulk FHIR file" do
      input = [
        %{
          "first_name" => "Alice",
          "last_name" => "Ant",
          "dob" => "01/02/1970",
          "sample_date" => "06/01/2020",
          "result_date" => "06/03/2020",
          "result" => "positive"
        },
        %{
          "first_name" => "Billy",
          "last_name" => "Bat",
          "dob" => "03/04/1990",
          "sample_date" => "06/06/2020",
          "result_date" => "06/07/2020",
          "result" => "negative"
        }
      ]

      {:ok, result} =
        DataFile.read(input, :bulk_fhir, &Function.identity/1,
          required: ~w{first_name last_name dob sample_date result_date result},
          optional: ~w{}
        )

      assert result == [
               %{
                 "first_name" => "Alice",
                 "last_name" => "Ant",
                 "dob" => "01/02/1970",
                 "sample_date" => "06/01/2020",
                 "result_date" => "06/03/2020",
                 "result" => "positive"
               },
               %{
                 "first_name" => "Billy",
                 "last_name" => "Bat",
                 "dob" => "03/04/1990",
                 "sample_date" => "06/06/2020",
                 "result_date" => "06/07/2020",
                 "result" => "negative"
               }
             ]
    end

    test "ignores unspecified headers in bulk FHIR" do
      input = [
        %{
          "column_a" => "value_a",
          "column_b" => "value_b",
          "column_c" => "value_c"
        }
      ]

      {:ok, result} =
        DataFile.read(input, :bulk_fhir, &Function.identity/1,
          required: ~w{column_a},
          optional: ~w{column_b}
        )

      assert result == [%{"column_a" => "value_a", "column_b" => "value_b"}]
    end

    test "fails if required header is missing in bulk FHIR" do
      input = [
        %{
          "column_a" => "value_a",
          "column_b" => "value_b"
        }
      ]

      assert {:error, :missing_headers, missing} =
               DataFile.read(input, :bulk_fhir, &Function.identity/1,
                 required: ~w{column_a column_b column_c column_d},
                 optional: ~w{}
               )

      assert Enum.sort(missing) == ["column_c", "column_d"]
    end

    test "allows optional headers in bulk FHIR" do
      input = [
        %{
          "column_a" => "value_a",
          "column_b" => "value_b",
          "optional_c" => "value_c"
        }
      ]

      {:ok, result} =
        DataFile.read(input, :bulk_fhir, &Function.identity/1,
          required: ~w{column_a column_b},
          optional: ~w{optional_c optional_d}
        )

      assert result == [%{"column_a" => "value_a", "column_b" => "value_b", "optional_c" => "value_c"}]
    end

    test "header transformer transforms headers in bulk FHIR" do
      input = [
        %{
          "first_name" => "Alice",
          "last_name" => "Ant"
        },
        %{
          "first_name" => "Billy",
          "last_name" => "Bat"
        }
      ]

      {:ok, result} =
        DataFile.read(input, :bulk_fhir, fn headers -> Enum.map(headers, &String.upcase/1) end,
          required: ~w{FIRST_NAME LAST_NAME},
          optional: ~w{}
        )

      assert result == [
               %{
                 "FIRST_NAME" => "Alice",
                 "LAST_NAME" => "Ant"
               },
               %{
                 "FIRST_NAME" => "Billy",
                 "LAST_NAME" => "Bat"
               }
             ]
    end
  end
end
