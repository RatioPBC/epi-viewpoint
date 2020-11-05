defmodule EpicenterWeb.Features.CaseInvestigationTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  @tag :skip
  test "user can edit the details of a case investigation with 'Other' symptom", %{conn: conn, user: user} do
    # import a person

    assert {:ok, _} =
             %{
               file_name: "test.csv",
               contents: """
               search_firstname_2 , search_lastname_1 , dateofbirth_8 , phonenumber_7 , caseid_0 , datecollected_36 , resultdate_42 , result_39 , orderingfacilityname_37 , person_tid , lab_result_tid , diagaddress_street1_3 , diagaddress_city_4 , diagaddress_state_5 , diagaddress_zip_6 , datereportedtolhd_44 , testname_38 , person_tid, sex_11, ethnicity_13, occupation_18   , race_12
               Alice              , Testuser          , 01/01/1970    , 1111111000    , 10000    , 06/01/2020       , 06/03/2020    , positive  , Lab Co South            , alice      , alice-result-1 ,                       ,                    ,                     ,                   , 06/05/2020           , TestTest    , alice     , female, HispanicOrLatino       , Rocket Scientist, Asian Indian
               """
             }
             |> Cases.Import.import_csv(user)

    [person] = Cases.list_people(:with_lab_results)

    conn
    |> Pages.Profile.visit(person)
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.click_start_interview_case_investigation("001")
    |> Pages.follow_live_view_redirect(conn)
    |> elem(1)
    |> Pages.CaseInvestigationStartInterview.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-interview-start-form",
      start_interview_form: %{
        "person_interviewed" => "Alice's guardian",
        "date_started" => "09/06/2020",
        "time_started" => "03:45",
        "time_started_am_pm" => "PM"
      }
    )
    |> Pages.Profile.click_edit_clinical_details_link("001")
    |> Pages.follow_live_view_redirect(conn)
    |> elem(1)
    |> Pages.CaseInvestigationClinicalDetails.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_date" => "09/06/2020",
        "symptoms" => ["fever", "chills", "groggy"],
        "symptoms_other" => true
      }
    )

    assert %{
             case_investigations: [
               %{
                 clinical_status: "symptomatic",
                 symptom_onset_date: ~D[2020-09-06],
                 symptoms: ["fever", "chills", "groggy"]
               }
             ]
           } = Cases.get_person(person.id) |> Cases.preload_demographics() |> Cases.preload_case_investigations()
  end

  test "user can edit the details of a case investigation", %{conn: conn, user: user} do
    # import a person

    assert {:ok, _} =
             %{
               file_name: "test.csv",
               contents: """
               search_firstname_2 , search_lastname_1 , dateofbirth_8 , phonenumber_7 , caseid_0 , datecollected_36 , resultdate_42 , result_39 , orderingfacilityname_37 , person_tid , lab_result_tid , diagaddress_street1_3 , diagaddress_city_4 , diagaddress_state_5 , diagaddress_zip_6 , datereportedtolhd_44 , testname_38 , person_tid, sex_11, ethnicity_13, occupation_18   , race_12
               Alice              , Testuser          , 01/01/1970    , 1111111000    , 10000    , 06/01/2020       , 06/03/2020    , positive  , Lab Co South            , alice      , alice-result-1 ,                       ,                    ,                     ,                   , 06/05/2020           , TestTest    , alice     , female, HispanicOrLatino       , Rocket Scientist, Asian Indian
               """
             }
             |> Cases.Import.import_csv(user)

    [person] = Cases.list_people(:with_lab_results)

    conn
    |> Pages.Profile.visit(person)
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.click_start_interview_case_investigation("001")
    |> Pages.follow_live_view_redirect(conn)
    |> elem(1)
    |> Pages.CaseInvestigationStartInterview.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-interview-start-form",
      start_interview_form: %{
        "person_interviewed" => "Alice's guardian",
        "date_started" => "09/06/2020",
        "time_started" => "03:45",
        "time_started_am_pm" => "PM"
      }
    )
    |> Pages.Profile.click_edit_clinical_details_link("001")
    |> Pages.follow_live_view_redirect(conn)
    |> elem(1)
    |> Pages.CaseInvestigationClinicalDetails.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_date" => "09/06/2020",
        "symptoms" => ["fever", "chills"]
      }
    )

    assert %{
             case_investigations: [
               %{
                 clinical_status: "symptomatic",
                 symptom_onset_date: ~D[2020-09-06],
                 symptoms: ["fever", "chills"]
               }
             ]
           } = Cases.get_person(person.id) |> Cases.preload_demographics() |> Cases.preload_case_investigations()
  end
end
