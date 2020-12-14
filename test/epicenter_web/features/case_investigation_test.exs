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
    |> Pages.CaseInvestigationClinicalDetails.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_on" => "09/06/2020",
        "symptoms" => ["fever", "chills", "groggy"],
        "symptoms_other" => true
      }
    )

    assert %{
             case_investigations: [
               %{
                 clinical_status: "symptomatic",
                 symptom_onset_on: ~D[2020-09-06],
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

    [person] = Cases.list_people(:with_positive_lab_results)

    conn
    |> Pages.Profile.visit(person)
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.click_start_interview_case_investigation("001")
    |> Pages.follow_live_view_redirect(conn)
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
    |> Pages.CaseInvestigationClinicalDetails.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-clinical-details-form",
      clinical_details_form: %{
        "clinical_status" => "symptomatic",
        "symptom_onset_on" => "09/06/2020",
        "symptoms" => ["fever", "chills"]
      }
    )
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.click_add_contact_link("001")
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.CaseInvestigationContact.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-contact-form",
      contact_form: %{
        "first_name" => "Connie",
        "last_name" => "Testuser",
        "relationship_to_case" => "Friend",
        "most_recent_date_together" => "10/31/2020",
        "under_18" => "false",
        "same_household" => "true",
        "phone" => "1111111111",
        preferred_language: "Haitian Creole"
      }
    )
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.refute_isolation_monitoring_visible("001")
    |> Pages.Profile.click_complete_case_investigation("001")
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.CaseInvestigationCompleteInterview.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-interview-complete-form",
      complete_interview_form: %{
        "date_completed" => "09/06/2020",
        "time_completed" => "03:45",
        "time_completed_am_pm" => "PM"
      }
    )
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.assert_isolation_monitoring_visible(%{status: "Pending isolation monitoring", number: "001"})
    |> Pages.Profile.click_add_isolation_dates("001")
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.CaseInvestigationIsolationMonitoring.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-isolation-monitoring-form",
      isolation_monitoring_form: %{
        "date_started" => "10/28/2020",
        "date_ended" => "11/10/2020"
      }
    )
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.assert_isolation_monitoring_visible(%{status: "Ongoing isolation monitoring (10 days remaining)", number: "001"})
    |> Pages.Profile.assert_isolation_order_details("001", %{order_sent_on: "Not sent", clearance_order_sent_on: "Not sent"})
    |> Pages.Profile.click_edit_isolation_order_details_link("001")
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.CaseInvestigationIsolationOrder.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-isolation-order-form",
      isolation_order_form: %{
        "order_sent_on" => "10/28/2020",
        "clearance_order_sent_on" => "11/10/2020"
      }
    )
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.assert_isolation_order_details("001", %{order_sent_on: "10/28/2020", clearance_order_sent_on: "11/10/2020"})
    |> Pages.Profile.click_conclude_isolation_monitoring("001")
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.CaseInvestigationConcludeIsolationMonitoring.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-conclude-isolation-monitoring-form",
      conclude_isolation_monitoring_form: %{
        "reason" => "successfully_completed"
      }
    )
    |> Pages.Profile.assert_here(person)
    |> Pages.Profile.assert_isolation_monitoring_visible(%{status: "Concluded isolation monitoring", number: "001"})
    |> Pages.Profile.assert_isolation_monitoring_has_history(
      Enum.join(
        [
          "Isolation dates: 10/28/2020 - 11/10/2020",
          "Concluded isolation monitoring on 10/31/2020 at 06:30am EDT. Successfully completed isolation period"
        ],
        " "
      )
    )

    Pages.Contacts.visit(conn)
    |> Pages.Contacts.assert_here()
    |> Pages.Contacts.assert_table_contents(
      [
        ["Name", "Exposure date"],
        ["Connie Testuser", "10/31/2020"]
      ],
      columns: ["Name", "Exposure date"]
    )

    assert %{
             case_investigations: [
               %{
                 id: case_investigation_id,
                 clinical_status: "symptomatic",
                 symptom_onset_on: ~D[2020-09-06],
                 symptoms: ["fever", "chills"]
               }
             ]
           } = Cases.get_person(person.id) |> Cases.preload_demographics() |> Cases.preload_case_investigations()

    assert %{
             exposures: [
               %{
                 exposed_person: %{
                   demographics: [
                     %{
                       first_name: "Connie",
                       last_name: "Testuser",
                       preferred_language: "Haitian Creole"
                     }
                   ],
                   phones: [%{number: "1111111111"}]
                 },
                 household_member: true,
                 most_recent_date_together: ~D[2020-10-31],
                 relationship_to_case: "Friend",
                 under_18: false
               }
             ]
           } =
             Cases.get_case_investigation(case_investigation_id)
             |> Cases.preload_contact_investigations()
  end
end
