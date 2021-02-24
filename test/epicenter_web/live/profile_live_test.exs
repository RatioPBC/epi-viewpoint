defmodule EpicenterWeb.ProfileLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias EpicenterWeb.Format
  alias EpicenterWeb.ProfileLive
  alias EpicenterWeb.Test.Components
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user
  @admin Test.Fixtures.admin()

  setup %{user: user} do
    person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Test.Fixtures.add_demographic_attrs(%{external_id: "987650"})
      |> Cases.create_person!()

    [person: load(person), user: user]
  end

  defp load(person) do
    Cases.get_person(person.id, @admin)
    |> Cases.preload_demographics()
    |> Cases.preload_emails()
    |> Cases.preload_phones()
  end

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}")

    assert_has_role(disconnected_html, "profile-page")
    assert_has_role(page_live, "profile-page")
  end

  test "records an audit log entry", %{conn: conn, person: person, user: user} do
    AuditLogAssertions.expect_phi_view_logs(2)
    Pages.Profile.visit(conn, person)
    AuditLogAssertions.verify_phi_view_logged(user, person)
  end

  test "records an audit log entry for any contacts", %{conn: conn, user: user, person: sick_person} do
    contact_investigation1 =
      create_contact_investigation(user, sick_person, %{}, %{}, %{
        tid: "contact_investigation",
        household_member: true,
        relationship_to_case: "Partner or roommate",
        most_recent_date_together: ~D{2020-08-06}
      })

    contact_investigation2 =
      create_contact_investigation(user, sick_person, %{sampled_on: ~D[2020-08-08]}, %{}, %{
        tid: "contact_investigation",
        household_member: true,
        relationship_to_case: "Partner or roommate",
        most_recent_date_together: ~D{2020-08-06}
      })

    # 10 audit logs seems excessive...
    AuditLogAssertions.expect_phi_view_logs(10)
    Pages.Profile.visit(conn, sick_person)
    AuditLogAssertions.verify_phi_view_logged(user, [contact_investigation1.exposed_person, contact_investigation2.exposed_person])
  end

  describe "potential duplicates" do
    defp create_person(tid, attrs) do
      Test.Fixtures.person_attrs(@admin, tid, %{}) |> Test.Fixtures.add_demographic_attrs(attrs) |> Cases.create_person!()
    end

    test "when there are potential duplicates, it shows the 'View potential duplicates' button", %{conn: conn} do
      person = create_person("person", %{last_name: "Testuser", first_name: "Alice"})
      create_person("duplicate", %{last_name: "Testuser", first_name: "Alice"})

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_potential_duplicates_button_present(true)
    end

    test "when there are not potential duplicates, it does not show the button", %{conn: conn} do
      person = create_person("person", %{last_name: "Testuser999", first_name: "Doug", dob: ~D[2004-01-01]})
      create_person("not-duplicate", %{last_name: "Testuser", first_name: "Bob", dob: ~D[1990-01-01]})

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_potential_duplicates_button_present(false)
    end

    test "when the person is archived and there are potential duplicates, it hides the 'View potential duplicates' button", %{conn: conn, user: user} do
      person = create_person("person", %{last_name: "Testuser", first_name: "Alice"})
      create_person("duplicate", %{last_name: "Testuser", first_name: "Alice"})
      Cases.archive_person(person.id, user, Test.Fixtures.admin_audit_meta())

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_potential_duplicates_button_present(false)
    end
  end

  describe "when the person has no identifying information" do
    test "showing person identifying information", %{conn: conn, person: person, user: user} do
      {:ok, _} =
        Cases.update_person(
          person,
          {%{demographics: [%{id: List.first(person.demographics).id, preferred_language: nil}]}, Test.Fixtures.audit_meta(user)}
        )

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_full_name("Alice Testuser")
      |> Pages.Profile.assert_external_id("ID: 987650")
      |> Pages.Profile.assert_date_of_birth("01/01/2000")
      |> Pages.Profile.assert_preferred_language("Unknown")
      |> Pages.Profile.assert_phone_numbers(["Unknown"])
      |> Pages.Profile.assert_email_addresses(["Unknown"])
      |> Pages.Profile.assert_addresses(["Unknown"])
    end

    test("email_addresses", %{person: person}, do: person |> ProfileLive.email_addresses() |> assert_eq([]))

    test("phone_numbers", %{person: person}, do: person |> ProfileLive.phone_numbers() |> assert_eq([]))
  end

  describe "when the person has identifying information" do
    setup %{person: person, user: user} do
      Test.Fixtures.email_attrs(user, person, "alice-a") |> Cases.create_email!()
      Test.Fixtures.email_attrs(user, person, "alice-preferred", is_preferred: true) |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, person, "phone-1", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(user, person, "phone-2", number: "111-111-1001", is_preferred: true) |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, person, "alice-address", 1000, type: "home") |> Cases.create_address!()
      Test.Fixtures.address_attrs(user, person, "alice-address-preferred", 2000, type: nil, is_preferred: true) |> Cases.create_address!()
      [person: load(person)]
    end

    test "showing person identifying information", %{conn: conn, person: person} do
      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_full_name("Alice Testuser")
      |> Pages.Profile.assert_date_of_birth("01/01/2000")
      |> Pages.Profile.assert_preferred_language("English")
      |> Pages.Profile.assert_phone_numbers(["(111) 111-1001", "(111) 111-1000"])
      |> Pages.Profile.assert_email_addresses(["alice-preferred@example.com", "alice-a@example.com"])
      |> Pages.Profile.assert_addresses(["2000 Test St, City, OH 00000", "1000 Test St, City, OH 00000"])
    end

    test "email_addresses", %{person: person} do
      person |> ProfileLive.email_addresses() |> assert_eq(["alice-preferred@example.com", "alice-a@example.com"])
    end

    test "phone_numbers", %{person: person, user: user} do
      Test.Fixtures.phone_attrs(user, person, "phone-3", number: "1-111-111-1009") |> Cases.create_phone!()
      person |> load() |> ProfileLive.phone_numbers() |> assert_eq(["(111) 111-1001", "(111) 111-1000", "+1 (111) 111-1009"])
    end

    test "editing the identifying information", %{conn: conn, person: person} do
      Pages.Profile.visit(conn, person)
      |> Pages.Profile.click_edit_identifying_information(conn)
      |> Pages.ProfileEdit.assert_here()
    end

    test "editing the demographics", %{conn: conn, person: person} do
      Pages.Profile.visit(conn, person)
      |> Pages.Profile.click_edit_demographics(conn)
      |> Pages.DemographicsEdit.assert_here()
    end
  end

  describe "when the person has no test results" do
    test "renders no lab result text", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      page_live
      |> assert_role_text("lab-results", "Lab Results No lab results")
    end
  end

  describe "when there are lab results" do
    defp build_lab_result(person, user, tid, sampled_on, analyzed_on, reported_on) do
      Test.Fixtures.lab_result_attrs(person, user, tid, sampled_on, %{
        result: "positive",
        request_facility_name: "Big Big Hospital",
        analyzed_on: analyzed_on,
        reported_on: reported_on,
        test_type: "PCR"
      })
      |> Cases.create_lab_result!()
    end

    test "shows lab results", %{conn: conn, person: person, user: user} do
      build_lab_result(person, user, "lab1", ~D[2020-04-10], ~D[2020-04-11], ~D[2020-04-12])
      build_lab_result(person, user, "lab2", ~D[2020-04-12], ~D[2020-04-13], ~D[2020-04-14])
      Test.Fixtures.lab_result_attrs(person, user, "lab3", ~D[2020-04-12], %{result: "dEtEcTeD"}) |> Cases.create_lab_result!()

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_lab_results([
        ["Collection", "Result", "Ordering Facility", "Analysis", "Reported", "Type"],
        ["04/12/2020", "Detected", "lab3 Lab, Inc.", "Unknown", "Unknown", "Unknown"],
        ["04/12/2020", "Positive", "Big Big Hospital", "04/13/2020", "04/14/2020", "PCR"],
        ["04/10/2020", "Positive", "Big Big Hospital", "04/11/2020", "04/12/2020", "PCR"]
      ])
    end

    test "orders by sampled_on (desc) and then reported_on (desc)", %{conn: conn, person: person, user: user} do
      build_lab_result(person, user, "lab4", ~D[2020-04-13], ~D[2020-04-20], ~D[2020-04-26])
      build_lab_result(person, user, "lab1", ~D[2020-04-15], ~D[2020-04-20], ~D[2020-04-25])
      build_lab_result(person, user, "lab3", ~D[2020-04-14], ~D[2020-04-20], ~D[2020-04-23])
      build_lab_result(person, user, "lab2", ~D[2020-04-14], ~D[2020-04-20], ~D[2020-04-24])

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_lab_results(
        [columns: ["Collection", "Reported"], tids: true],
        [
          ["Collection", "Reported", :tid],
          ["04/15/2020", "04/25/2020", "lab1"],
          ["04/14/2020", "04/24/2020", "lab2"],
          ["04/14/2020", "04/23/2020", "lab3"],
          ["04/13/2020", "04/26/2020", "lab4"]
        ]
      )
    end

    test "when the person lacks a value for a field of a lab result, show unknown", %{conn: conn, person: person, user: user} do
      Test.Fixtures.lab_result_attrs(person, user, "lab1", nil, %{
        result: nil,
        request_facility_name: nil,
        analyzed_on: nil,
        reported_on: nil,
        test_type: nil
      })
      |> Cases.create_lab_result!()

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_lab_results([
        ["Collection", "Result", "Ordering Facility", "Analysis", "Reported", "Type"],
        ["Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown"]
      ])
    end
  end

  describe "when person has been merged" do
    test "redirects to the canonical record", %{conn: conn, person: canonical_person} do
      duplicate_person = Test.Fixtures.person_attrs(@admin, "duplicate-person") |> Cases.create_person!()
      Cases.merge_people([duplicate_person], canonical_person.id, @admin, Test.Fixtures.admin_audit_meta())

      Pages.Profile.visit(conn, duplicate_person)
      |> Pages.Profile.assert_here(canonical_person)
    end

    test "follows redirection chain when multiple duplicates have been merged", %{conn: conn, person: canonical_person} do
      duplicate_person_1 = Test.Fixtures.person_attrs(@admin, "duplicate-person-1") |> Cases.create_person!()
      duplicate_person_2 = Test.Fixtures.person_attrs(@admin, "duplicate-person-2") |> Cases.create_person!()

      Cases.merge_people([duplicate_person_2], duplicate_person_1.id, @admin, Test.Fixtures.admin_audit_meta())
      Cases.merge_people([duplicate_person_1], canonical_person.id, @admin, Test.Fixtures.admin_audit_meta())

      Pages.Profile.visit(conn, duplicate_person_2)
      |> Pages.Profile.assert_here(canonical_person)
    end

    test "doesn't get stuck in redirect cycles", %{conn: conn} do
      duplicate_person_1 = Test.Fixtures.person_attrs(@admin, "duplicate-person-1") |> Cases.create_person!()
      duplicate_person_2 = Test.Fixtures.person_attrs(@admin, "duplicate-person-2") |> Cases.create_person!()

      Cases.merge_people([duplicate_person_2], duplicate_person_1.id, @admin, Test.Fixtures.admin_audit_meta())
      Cases.merge_people([duplicate_person_1], duplicate_person_2.id, @admin, Test.Fixtures.admin_audit_meta())

      Pages.Profile.visit(conn, duplicate_person_1)
    end
  end

  describe "case investigations" do
    test "it shows a pending case investigation", %{conn: conn, person: person, user: user} do
      case_investigation = create_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{
        initiated_by: "positive lab result collected on 01/02/2020 at Big Big Hospital",
        status: "Pending interview",
        status_value: "pending",
        reported_on: "08/07/2020",
        timestamp: Format.date(case_investigation.inserted_at)
      })
      |> Pages.Profile.refute_clinical_details_showing("001")
      |> Pages.Profile.refute_contacts_showing("001")
    end

    test "if lab result is missing reported_on, initiated date is unknown", %{conn: conn, person: person, user: user} do
      case_investigation = create_case_investigation(person, user, "case_investigation", nil)

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{
        initiated_by: "positive lab result collected on 01/02/2020 at Big Big Hospital",
        status: "Pending interview",
        status_value: "pending",
        reported_on: "Unknown",
        timestamp: Format.date(case_investigation.inserted_at)
      })
    end

    test "if there are no case investigations, don't  show a case investigation", %{conn: conn, person: person} do
      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_no_case_investigations()
    end

    test "starting a case investigation", %{conn: conn, person: person, user: user} do
      case_investigation = create_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.click_start_interview_case_investigation("001")
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/start-interview")
    end

    test "navigating to discontinue a case investigation", %{conn: conn, person: person, user: user} do
      lab_result = build_lab_result(person, user, "lab_result", ~D[2020-08-05], ~D[2020-08-06], ~D[2020-08-07])

      case_investigation =
        person
        |> Test.Fixtures.case_investigation_attrs(lab_result, user, "case_investigation")
        |> Cases.create_case_investigation!()

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.click_discontinue_case_investigation("001")
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/discontinue")
    end

    test "discontinued case investigations say so", %{conn: conn, person: person, user: user} do
      date = ~N[2020-01-02 01:00:07]

      case_investigation =
        create_case_investigation(person, user, "case_investigation", nil, %{
          interview_discontinued_at: date,
          interview_discontinue_reason: "Unable to reach"
        })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{
        initiated_by: "positive lab result collected on 01/02/2020 at Big Big Hospital",
        status: "Discontinued",
        status_value: "discontinued",
        reported_on: "Unknown",
        timestamp: Format.date(case_investigation.inserted_at)
      })
      # in discontinued case investigations, start and discontinue buttons move down to history section
      |> Pages.Profile.refute_start_interview_button("001")
      |> Pages.Profile.refute_discontinue_interview_button("001")
      |> Pages.Profile.refute_complete_interview_button("001")
      |> Pages.Profile.assert_case_investigation_has_history("Discontinued interview on 01/01/2020 at 08:00pm EST: Unable to reach")
      |> Pages.Profile.refute_clinical_details_showing("001")
      |> Pages.Profile.refute_contacts_showing("001")
    end

    test "discontinuation reason can be edited", %{conn: conn, person: person, user: user} do
      case_investigation =
        create_case_investigation(person, user, "case_investigation", nil, %{
          interview_discontinued_at: NaiveDateTime.utc_now(),
          interview_discontinue_reason: "Unable to reach"
        })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.click_edit_discontinuation_link("001")
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/discontinue")
    end

    test "started case investigations say so", %{conn: conn, person: person, user: user} do
      case_investigation =
        create_case_investigation(person, user, "case_investigation", nil, %{
          interview_started_at: NaiveDateTime.utc_now(),
          clinical_status: "symptomatic"
        })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{
        initiated_by: "positive lab result collected on 01/02/2020 at Big Big Hospital",
        status: "Ongoing interview",
        status_value: "started",
        reported_on: "Unknown",
        timestamp: Format.date(case_investigation.inserted_at)
      })
      |> Pages.Profile.assert_clinical_details_showing("001", %{clinical_status: "Symptomatic"})
      |> Pages.Profile.assert_contacts_showing("001")
    end

    test "started case investigations that lack a clinical details show the values as 'None'", %{conn: conn, person: person, user: user} do
      create_case_investigation(person, user, "case_investigation", nil, %{
        interview_started_at: NaiveDateTime.utc_now(),
        clinical_status: nil,
        symptom_onset_on: nil
      })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_clinical_details_showing("001", %{clinical_status: "None", symptom_onset_on: "None", symptoms: "None"})
    end

    test "started case investigations with a clinical details asymptomatic render correctly", %{conn: conn, person: person, user: user} do
      create_case_investigation(person, user, "case_investigation", nil, %{
        interview_started_at: NaiveDateTime.utc_now(),
        clinical_status: "asymptomatic",
        symptom_onset_on: ~D[2020-09-12],
        symptoms: ["nasal_congestion", "Custom Symptom"]
      })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_clinical_details_showing("001", %{
        clinical_status: "Asymptomatic",
        symptom_onset_on: "09/12/2020",
        symptoms: "Nasal congestion, Custom Symptom"
      })
    end

    test "started case investigations with a unknown clinical details render correctly", %{conn: conn, person: person, user: user} do
      create_case_investigation(person, user, "case_investigation", nil, %{
        interview_started_at: NaiveDateTime.utc_now(),
        clinical_status: "unknown"
      })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_clinical_details_showing("001", %{clinical_status: "Unknown"})
    end

    test "started case investigations with empty lists of symptoms show None for symptoms", %{conn: conn, person: person, user: user} do
      create_case_investigation(person, user, "case_investigation", nil, %{
        interview_started_at: NaiveDateTime.utc_now(),
        symptoms: []
      })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_clinical_details_showing("001", %{symptoms: "None"})
    end

    test "started case investigations can be completed", %{conn: conn, person: person, user: user} do
      create_case_investigation(person, user, "case_investigation", nil, %{interview_started_at: NaiveDateTime.utc_now()})

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigation_complete_button_title("001", "Complete interview")
    end

    test "started case investigations show contacts", %{conn: conn, person: person, user: user} do
      case_investigation =
        create_case_investigation(person, user, "case_investigation", ~D[2020-08-07], %{interview_started_at: NaiveDateTime.utc_now()})

      {:ok, completed_contact_investigation} =
        ContactInvestigations.create(
          {%{
             exposing_case_id: case_investigation.id,
             relationship_to_case: "Family",
             most_recent_date_together: ~D[2020-10-31],
             household_member: true,
             under_18: true,
             guardian_name: "Jacob",
             guardian_phone: "(111) 111-1832",
             exposed_person: %{
               tid: "complete",
               demographics: [
                 %{
                   source: "form",
                   first_name: "Complete",
                   last_name: "Testuser",
                   preferred_language: "Haitian Creole"
                 }
               ],
               phones: [
                 %{
                   number: "1111111542"
                 }
               ]
             }
           }, Test.Fixtures.admin_audit_meta()}
        )

      {:ok, _} =
        ContactInvestigations.create(
          {%{
             exposing_case_id: case_investigation.id,
             relationship_to_case: "Friend",
             most_recent_date_together: ~D[2020-11-30],
             household_member: false,
             under_18: false,
             exposed_person: %{
               demographics: [
                 %{
                   source: "form",
                   first_name: "Adult",
                   last_name: "Testuser"
                 }
               ],
               phones: [
                 %{
                   number: "1111111542"
                 },
                 %{
                   number: "1111111543"
                 }
               ]
             }
           }, Test.Fixtures.admin_audit_meta()}
        )

      {:ok, _} =
        ContactInvestigations.create(
          {%{
             exposing_case_id: case_investigation.id,
             relationship_to_case: "Friend",
             most_recent_date_together: ~D[2020-11-30],
             household_member: false,
             under_18: false,
             exposed_person: %{
               demographics: [
                 %{
                   source: "form",
                   first_name: "Partial",
                   last_name: "Testuser"
                 }
               ],
               phones: []
             }
           }, Test.Fixtures.admin_audit_meta()}
        )

      view = Pages.Profile.visit(conn, person)

      assert [
               "Complete Testuser Family Household Minor Guardian: Jacob (111) 111-1832 Haitian Creole Last together 10/31/2020",
               "Adult Testuser Friend (111) 111-1542 (111) 111-1543 Last together 11/30/2020",
               "Partial Testuser Friend Last together 11/30/2020"
             ] =
               view
               |> Pages.Profile.assert_contacts_showing("001")
               |> Pages.Profile.case_investigation_contact_details("001")

      exposed_person = Cases.get_person(completed_contact_investigation.exposed_person_id, user)

      view
      |> Pages.Profile.click_on_contact("001", "Complete Testuser")
      |> Pages.follow_live_view_redirect(conn)
      |> Pages.Profile.assert_here(exposed_person)
    end

    test "a contact can be edited", %{conn: conn, person: person, user: user} do
      case_investigation =
        create_case_investigation(person, user, "case_investigation", ~D[2020-08-07], %{interview_started_at: NaiveDateTime.utc_now()})

      {:ok, contact_investigation} =
        ContactInvestigations.create(
          {%{
             exposing_case_id: case_investigation.id,
             relationship_to_case: "Family",
             most_recent_date_together: ~D[2020-10-31],
             household_member: true,
             under_18: true,
             guardian_name: "Jacob",
             exposed_person: %{
               demographics: [
                 %{
                   source: "form",
                   first_name: "Complete",
                   last_name: "Testuser",
                   preferred_language: "Haitian Creole"
                 }
               ],
               phones: [
                 %{
                   number: "1111111542"
                 }
               ]
             }
           }, Test.Fixtures.admin_audit_meta()}
        )

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.click_edit_contact_link(contact_investigation)
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/contact/#{contact_investigation.id}")
    end

    test "a contact can be removed", %{conn: conn, person: person, user: user} do
      case_investigation =
        create_case_investigation(person, user, "case_investigation", ~D[2020-08-07], %{interview_started_at: NaiveDateTime.utc_now()})

      {:ok, contact_investigation} =
        ContactInvestigations.create(
          {%{
             exposing_case_id: case_investigation.id,
             relationship_to_case: "Family",
             most_recent_date_together: ~D[2020-10-31],
             household_member: true,
             under_18: true,
             guardian_name: "Jacob",
             exposed_person: %{
               demographics: [
                 %{
                   source: "form",
                   first_name: "Complete",
                   last_name: "Testuser",
                   preferred_language: "Haitian Creole"
                 }
               ],
               phones: [
                 %{
                   number: "1111111542"
                 }
               ]
             }
           }, Test.Fixtures.admin_audit_meta()}
        )

      view = Pages.Profile.visit(conn, person)
      view |> Pages.Profile.click_remove_contact_link(contact_investigation)

      case_investigation = Cases.get_case_investigation(case_investigation.id, user) |> Cases.preload_contact_investigations(user)
      assert case_investigation.contact_investigations == []

      assert [] =
               view
               |> Pages.Profile.case_investigation_contact_details("001")
    end

    test "case investigations with completed interviews render correctly", %{conn: conn, person: person, user: user} do
      completed_at = ~U[2020-11-05 19:57:00Z]
      started_at = ~U[2020-11-05 18:57:00Z]

      case_investigation =
        create_case_investigation(person, user, "case_investigation", nil, %{
          interview_completed_at: completed_at,
          interview_started_at: started_at
        })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{
        initiated_by: "positive lab result collected on 01/02/2020 at Big Big Hospital",
        status: "Completed interview",
        status_value: "completed-interview",
        reported_on: "Unknown",
        timestamp: Format.date(case_investigation.inserted_at)
      })
      |> Pages.Profile.assert_case_investigation_has_history(
        "Started interview with Alice Testuser on 11/05/2020 at 01:57pm EST Completed interview on 11/05/2020 at 02:57pm EST"
      )
      |> Pages.Profile.refute_complete_interview_button("001")
      |> Pages.Profile.click_edit_complete_interview_link("001")
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/complete-interview")
    end

    test "case investigations with isolation monitoring dates can be edited", %{conn: conn, person: person, user: user} do
      case_investigation =
        create_case_investigation(person, user, "case_investigation", nil, %{
          interview_completed_at: ~U[2020-10-05 19:57:00Z],
          interview_started_at: ~U[2020-10-05 18:57:00Z],
          isolation_monitoring_starts_on: ~D[2020-11-05],
          isolation_monitoring_ends_on: ~D[2020-11-15]
        })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_isolation_monitoring_visible(%{status: "Ongoing isolation monitoring (15 days remaining)", number: "001"})
      |> Pages.Profile.assert_isolation_monitoring_has_history("Isolation dates: 11/05/2020 - 11/15/2020")
      |> Pages.Profile.click_edit_isolation_monitoring_link("001")
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/isolation-monitoring")
    end

    test "case investigations with an isolation monitoring conclusion can be edited", %{conn: conn, person: person, user: user} do
      case_investigation =
        create_case_investigation(person, user, "case_investigation", nil, %{
          interview_completed_at: ~U[2020-10-05 19:57:00Z],
          interview_started_at: ~U[2020-10-05 18:57:00Z],
          isolation_concluded_at: ~U[2020-11-15 19:57:00Z],
          isolation_conclusion_reason: "successfully_completed",
          isolation_monitoring_ends_on: ~D[2020-11-15],
          isolation_monitoring_starts_on: ~D[2020-11-05]
        })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_isolation_monitoring_visible(%{status: "Concluded isolation monitoring", number: "001"})
      |> Pages.Profile.assert_isolation_monitoring_has_history(
        Enum.join(
          [
            "Isolation dates: 11/05/2020 - 11/15/2020",
            "Concluded isolation monitoring on 11/15/2020 at 02:57pm EST. Successfully completed isolation period"
          ],
          " "
        )
      )
      |> Pages.Profile.click_edit_isolation_monitoring_conclusion_link("001")
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/conclude-isolation-monitoring")
    end

    test "can see existing notes", %{person: person, user: user, conn: conn} do
      case_investigation = create_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

      Test.Fixtures.case_investigation_note_attrs(case_investigation, user, "note-a", %{text: "older note"})
      |> Cases.create_investigation_note!()

      Test.Fixtures.case_investigation_note_attrs(case_investigation, user, "note-b", %{text: "newer note"})
      |> Cases.create_investigation_note!()

      view =
        Pages.Profile.visit(conn, person)
        |> Pages.Profile.assert_case_investigations(%{
          initiated_by: "positive lab result collected on 01/02/2020 at Big Big Hospital",
          status: "Pending interview",
          status_value: "pending",
          reported_on: "08/07/2020",
          timestamp: Format.date(case_investigation.inserted_at)
        })

      assert [%{text: "newer note"}, %{text: "older note"}] = Pages.Profile.case_investigation_notes(view, "001")
    end

    test "can add a new note", %{person: person, user: user, conn: conn} do
      case_investigation = create_case_investigation(person, user, "case_investigation", ~D[2020-08-07])
      username = user.name

      view =
        Pages.Profile.visit(conn, person)
        |> Pages.Profile.change_case_investigation_note_form("001", %{"text" => "A new note"})
        |> Pages.Profile.add_case_investigation_note("001", "A new note")

      view |> render()

      [note] = Pages.Profile.case_investigation_notes(view, "001")
      assert %{text: "A new note", author: ^username} = note
      assert {:ok, _} = Epicenter.DateParser.parse_mm_dd_yyyy(note.date)
      %{"form_field_data[text]" => text} = Pages.form_state(view)
      assert text |> Euclid.Exists.blank?()

      assert [note] = case_investigation |> Cases.preload_investigation_notes() |> Map.get(:notes)
      assert_recent_audit_log(note, user, action: "create-case-investigation-note", event: "profile-case-investigation-note-submission")
    end

    test "can't add an empty note", %{person: person, user: user, conn: conn} do
      create_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.add_case_investigation_note("001", "")
      |> Pages.Profile.assert_case_investigation_note_validation_messages("001", %{"form_field_data[text]" => "can't be blank"})
    end

    test "lets you remove your note", %{person: person, user: user, conn: conn} do
      create_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

      view =
        Pages.Profile.visit(conn, person)
        |> Pages.Profile.add_case_investigation_note("001", "this is my note")

      view |> render()

      [note] = Pages.Profile.case_investigation_notes(view, "001")

      assert Components.InvestigationNote.delete_note(view, note.id) == :ok

      assert [] = Pages.Profile.case_investigation_notes(view, "001")

      assert_recent_audit_log(note, user, action: "delete-case-investigation-note", event: "profile-case-investigation-note-deletion")
    end

    test "doesn't let you remove someone else's note", %{person: person, user: user, conn: conn} do
      other_user = Epicenter.AccountsFixtures.user_fixture(%{tid: "someone_else"})
      case_investigation = create_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

      someone_elses_note =
        Test.Fixtures.case_investigation_note_attrs(case_investigation, other_user, "note-a", %{text: "some other user's note"})
        |> Cases.create_investigation_note!()
        |> Cases.preload_author()

      view = Pages.Profile.visit(conn, person)

      assert :delete_button_not_found = Components.InvestigationNote.delete_note(view, someone_elses_note.id)
    end

    test "warns you that there are changes if you try to navigate away", %{person: person, user: user, conn: conn} do
      create_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

      Pages.Profile.visit(conn, person)
      |> Pages.refute_confirmation_prompt_active()
      |> Pages.Profile.change_case_investigation_note_form("001", %{"text" => "something present"})
      |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")
    end
  end

  describe "contact investigations" do
    test "show up", %{conn: conn, user: user, person: sick_person} do
      contact_investigation =
        create_contact_investigation(user, sick_person, %{}, %{}, %{
          tid: "contact_investigation",
          household_member: true,
          relationship_to_case: "Partner or roommate",
          most_recent_date_together: ~D{2020-08-06}
        })

      contact_investigation_id = contact_investigation.id
      exposed_person = contact_investigation.exposed_person

      view = Pages.Profile.visit(conn, exposed_person)

      assert [
               %{
                 id: ^contact_investigation_id,
                 title: "Contact investigation 08/06/2020",
                 initiating_case_text: "Initiated by index case #987650",
                 minor_details: [],
                 exposure_details: ["Same household", "Partner or roommate", "Last together on 08/06/2020"],
                 interview_buttons: ["Start interview", "Discontinue"]
               }
             ] = Pages.Profile.contact_investigations(view)

      actual = Pages.Profile.contact_investigations(view) |> hd()

      expected_creation_timestamp = "Created on #{Format.date(contact_investigation.inserted_at)}"
      assert ^expected_creation_timestamp = actual.creation_timestamp
    end

    test "navigating to the exposing case", %{conn: conn, user: user, person: sick_person} do
      contact_investigation =
        create_contact_investigation(user, sick_person, %{}, %{}, %{
          tid: "contact_investigation"
        })

      Pages.Profile.visit(conn, contact_investigation.exposed_person)
      |> Pages.Profile.click_on_exposing_case(contact_investigation.tid)
      |> Pages.follow_live_view_redirect(conn)
      |> Pages.Profile.assert_here(sick_person)
    end

    test "the contact investigation is not from the same household", %{conn: conn, user: user, person: sick_person} do
      contact_investigation =
        create_contact_investigation(user, sick_person, %{}, %{}, %{
          tid: "contact_investigation",
          household_member: false,
          relationship_to_case: "Healthcare worker",
          most_recent_date_together: ~D{2020-08-06}
        })

      view = Pages.Profile.visit(conn, contact_investigation.exposed_person)

      assert [
               %{
                 exposure_details: ["Healthcare worker", "Last together on 08/06/2020"]
               }
             ] = Pages.Profile.contact_investigations(view)
    end

    test "use the viewpoint id if external id is missing", %{conn: conn, user: user} do
      sick_person = Test.Fixtures.person_attrs(user, "sick_person ") |> Cases.create_person!()
      contact_investigation = create_contact_investigation(user, sick_person, %{}, %{}, %{tid: "contact_investigation"})

      contact_investigation_id = contact_investigation.id
      view = Pages.Profile.visit(conn, contact_investigation.exposed_person)
      initiating_case_text = "Initiated by index case \##{sick_person.id}"

      assert [%{id: ^contact_investigation_id, initiating_case_text: ^initiating_case_text}] = Pages.Profile.contact_investigations(view)
    end

    test "the exposed person is a minor", %{conn: conn, user: user, person: sick_person} do
      contact_investigation =
        create_contact_investigation(
          user,
          sick_person,
          %{},
          %{},
          %{guardian_name: "Alex Testuser", guardian_phone: "1111111222", under_18: true}
        )

      view = Pages.Profile.visit(conn, contact_investigation.exposed_person)

      assert [
               %{
                 minor_details: ["Minor", "Guardian: Alex Testuser", "Guardian phone: (111) 111-1222"]
               }
             ] = Pages.Profile.contact_investigations(view)
    end

    test "can add a new note", %{person: sick_person, user: user, conn: conn} do
      contact_investigation = create_contact_investigation(user, sick_person, %{}, %{}, %{tid: "contact_investigation"})
      username = user.name

      view =
        Pages.Profile.visit(conn, contact_investigation.exposed_person)
        |> Pages.Profile.add_contact_investigation_note(contact_investigation.tid, "A new note")

      view |> render()

      assert [note] = contact_investigation |> Cases.preload_investigation_notes() |> Map.get(:notes)
      assert_recent_audit_log(note, user, action: "create-contact-investigation-note", event: "profile-contact-investigation-note-submission")

      [note] = Pages.Profile.contact_investigation_notes(view, contact_investigation.tid)
      assert %{text: "A new note", author: ^username} = note
      assert {:ok, _} = Epicenter.DateParser.parse_mm_dd_yyyy(note.date)
      %{"form_field_data[text]" => text} = Pages.form_state(view)
      assert text |> Euclid.Exists.blank?()
    end

    test "lets you remove your note", %{person: sick_person, user: user, conn: conn} do
      contact_investigation = create_contact_investigation(user, sick_person, %{}, %{}, %{tid: "contact_investigation"})

      view =
        Pages.Profile.visit(conn, contact_investigation.exposed_person)
        |> Pages.Profile.add_contact_investigation_note(contact_investigation.tid, "A new note")

      view |> render()

      [note] = Pages.Profile.contact_investigation_notes(view, contact_investigation.tid)

      assert :ok = Components.InvestigationNote.delete_note(view, note.id)

      assert [] = Pages.Profile.contact_investigation_notes(view, contact_investigation.tid)

      assert_recent_audit_log(note, user, action: "delete-contact-investigation-note", event: "profile-contact-investigation-note-deletion")
    end

    test "warns you that there are changes if you try to navigate away", %{person: sick_person, user: user, conn: conn} do
      contact_investigation = create_contact_investigation(user, sick_person, %{}, %{}, %{tid: "contact_investigation"})

      Pages.Profile.visit(conn, contact_investigation.exposed_person)
      |> Pages.refute_confirmation_prompt_active()
      |> Pages.Profile.change_contact_investigation_note_form(contact_investigation.tid, %{"text" => "something present"})
      |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")
    end

    test "looking at a discontinued contact investigation", %{conn: conn, user: user, person: sick_person} do
      contact_investigation =
        create_contact_investigation(
          user,
          sick_person,
          %{},
          %{},
          %{
            tid: "contact_investigation",
            interview_discontinued_at: ~U[2020-12-08 11:00:00Z],
            interview_discontinue_reason: "Transferred to another jurisdiction"
          }
        )

      view = Pages.Profile.visit(conn, contact_investigation.exposed_person)

      assert [
               %{
                 interview_buttons: [],
                 interview_history_items: ["Discontinued interview on 12/08/2020 at 06:00am EST: Transferred to another jurisdiction"]
               }
             ] = Pages.Profile.contact_investigations(view)

      view
      |> Pages.Profile.click_edit_interview_discontinuation_details("contact_investigation")
      |> assert_redirects_to("/contact-investigations/#{contact_investigation.id}/discontinue")
    end

    test "looking at a started contact investigation interview", %{conn: conn, user: user, person: sick_person} do
      contact_investigation =
        create_contact_investigation(user, sick_person, %{}, %{}, %{tid: "contact_investigation", interview_started_at: ~U[2020-12-08 11:00:00Z]})

      view = Pages.Profile.visit(conn, contact_investigation.exposed_person)

      assert [
               %{
                 interview_buttons: ["Complete interview", "Discontinue"],
                 interview_history_items: ["Started interview with Caroline Testuser on 12/08/2020 at 06:00am EST"]
               }
             ] = Pages.Profile.contact_investigations(view)

      view
      |> Pages.Profile.click_edit_interview_start_details("contact_investigation")
      |> assert_redirects_to("/contact-investigations/#{contact_investigation.id}/start-interview")
    end

    test "looking at a complete contact investigation interview", %{conn: conn, user: user, person: sick_person} do
      contact_investigation =
        create_contact_investigation(user, sick_person, %{}, %{}, %{
          tid: "contact_investigation",
          interview_started_at: ~U[2020-12-08 11:00:00Z],
          interview_completed_at: ~U[2020-12-08 11:30:00Z]
        })

      view = Pages.Profile.visit(conn, contact_investigation.exposed_person)

      assert [
               %{
                 interview_buttons: [],
                 interview_history_items: [
                   "Started interview with Caroline Testuser on 12/08/2020 at 06:00am EST",
                   "Completed interview on 12/08/2020 at 06:30am EST"
                 ]
               }
             ] = Pages.Profile.contact_investigations(view)

      view
      |> Pages.Profile.click_edit_interview_completion_details("contact_investigation")
      |> assert_redirects_to("/contact-investigations/#{contact_investigation.id}/complete-interview")
    end
  end

  describe "place visits" do
    setup %{person: person} do
      lab_result = Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", ~D[2020-10-27]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "case-investigation", %{symptom_onset_on: ~D[2021-02-18]})
        |> Cases.create_case_investigation!()

      place = Test.Fixtures.place_attrs(@admin, "place", %{name: "the best place", type: "retail"}) |> Cases.create_place!()

      Test.Fixtures.place_address_attrs(@admin, place, "place-address-1", 1111)
      |> Cases.create_place_address!()

      visit =
        Test.Fixtures.visit_attrs(@admin, "visit", place, case_investigation, %{
          relationship: "employee",
          occurred_on: ~D[2020-09-06]
        })
        |> Cases.create_visit!()

      [place: place, visit: visit, case_investigation: case_investigation]
    end

    test " it displays place and date", %{case_investigation: case_investigation, person: person, conn: conn} do
      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_visit_address(case_investigation, "the best place", "1111 Test St, City, OH 00000")
      |> Pages.Profile.assert_visit(case_investigation, "retail", "employee", "1111111234", "09/06/2020")
    end
  end

  describe "assigning and unassigning user to a person" do
    defp table_contents(live, opts),
      do: live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "people"))

    setup %{person: person, user: user} do
      Test.Fixtures.address_attrs(user, person, "address1", 1000) |> Cases.create_address!()
      Test.Fixtures.lab_result_attrs(person, user, "lab1", ~D[2020-04-10]) |> Cases.create_lab_result!()
      assignee = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "assignee") |> Accounts.register_user!()
      [person: person, assignee: assignee]
    end

    test "assign_updated_person", %{assignee: assignee, person: alice, user: user} do
      {:ok, [alice]} =
        Cases.assign_user_to_people(
          user_id: assignee.id,
          people_ids: [alice.id],
          audit_meta: Test.Fixtures.audit_meta(user),
          current_user: @admin
        )

      updated_socket = %Phoenix.LiveView.Socket{assigns: %{person: alice, current_user: user}} |> ProfileLive.assign_updated_person(alice)
      assert updated_socket.assigns.person.addresses |> tids() == ["address1"]
      assert updated_socket.assigns.person.assigned_to.tid == "assignee"
      assert updated_socket.assigns.person.lab_results |> tids() == ["lab1"]
      assert updated_socket.assigns.person.tid == "alice"
    end

    test "people can be assigned to users on index and show page", %{
      conn: conn,
      person: alice,
      assignee: assignee,
      user: user
    } do
      billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(billy, user, "billy-lab1", ~D[2020-04-12]) |> Cases.create_lab_result!()
      Test.Fixtures.case_investigation_attrs(billy, lab_result, user, "") |> Cases.create_case_investigation!()

      alice = alice |> Cases.preload_lab_results()
      Test.Fixtures.case_investigation_attrs(alice, hd(alice.lab_results), user, "") |> Cases.create_case_investigation!()

      {:ok, index_page_live, _html} = live(conn, "/people")
      {:ok, show_page_live, _html} = live(conn, "/people/#{alice.id}")

      index_page_live
      |> table_contents(columns: ["Name", "Assignee"])
      |> assert_eq([
        ["Name", "Assignee"],
        ["Alice Testuser", ""],
        ["Billy Testuser", ""]
      ])

      # choose "assignee" via show page
      assert_select_dropdown_options(view: show_page_live, data_role: "users", expected: ["Unassigned", "assignee", "fixture admin", "user"])
      show_page_live |> element("#assignment-form") |> render_change(%{"user" => assignee.id})
      assert_selected_dropdown_option(view: show_page_live, data_role: "users", expected: ["assignee"])
      assert Cases.get_person(alice.id, user) |> Cases.preload_assigned_to() |> Map.get(:assigned_to) |> Map.get(:tid) == "assignee"

      # unassign "assignee" via show page
      show_page_live |> element("#assignment-form") |> render_change(%{"user" => "-unassigned-"})
      assert_selected_dropdown_option(view: show_page_live, data_role: "users", expected: ["Unassigned"])
      assert Cases.get_person(alice.id, user) |> Cases.preload_assigned_to() |> Map.get(:assigned_to) == nil
    end

    test "handles assign_users message when the changed people include the current person", %{person: alice, assignee: assignee, user: user} do
      billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()
      socket = %Phoenix.LiveView.Socket{assigns: %{person: alice, current_user: user}}

      {:noreply, updated_socket} = ProfileLive.handle_info({:people, [%{alice | tid: "updated-alice"}, billy]}, socket)
      assert updated_socket.assigns.person.tid == "updated-alice"
    end

    test "handles assign_users message when the changed people do not include the current person", %{person: alice, assignee: assignee} do
      billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()
      socket = %Phoenix.LiveView.Socket{assigns: %{person: alice}}

      {:noreply, updated_socket} = ProfileLive.handle_info({:people, [%{billy | tid: "updated-billy"}]}, socket)
      assert updated_socket.assigns.person.tid == "alice"
    end

    test "handles {:people, updated_people} when csv upload includes new values", %{conn: conn, person: alice, user: user} do
      socket = %Phoenix.LiveView.Socket{assigns: %{person: alice, current_user: user}}
      {:ok, show_page_live, _html} = live(conn, "/people/#{alice.id}")
      assert_role_text(show_page_live, "addresses", "1000 Test St, City, OH 00000")

      Test.Fixtures.address_attrs(user, alice, "address2", 2000) |> Cases.create_address!()
      {:noreply, updated_socket} = ProfileLive.handle_info({:people, [%{alice | tid: "updated-alice"}]}, socket)
      assert updated_socket.assigns.person.tid == "updated-alice"
      assert updated_socket.assigns.person.addresses |> tids() == ["address1", "address2"]
    end
  end

  describe "demographics" do
    setup %{person: person, user: user} do
      person_attrs = Test.Fixtures.add_demographic_attrs(%{tid: "profile-live-person"}, %{id: Euclid.Extra.List.only!(person.demographics).id})
      Cases.update_person(person, {person_attrs, Test.Fixtures.audit_meta(user)})
      :ok
    end

    test "showing person demographics", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "gender-identity", "Female")
      assert_role_text(page_live, "sex-at-birth", "Female")
      assert_role_text(page_live, "ethnicity", "Not Hispanic, Latino/a, or Spanish origin")
      assert_role_list(page_live, "race", ["Asian", "Filipino"])
      assert_role_text(page_live, "marital-status", "Single")
      assert_role_text(page_live, "employment", "Part time")
      assert_role_text(page_live, "occupation", "architect")
      assert_role_text(page_live, "notes", "lorem ipsum")
      assert_role_text(page_live, "date-of-birth", "01/01/2000")
    end

    test "showing person demographics when information is missing", %{conn: conn, person: person, user: user} do
      person_attrs =
        Test.Fixtures.add_demographic_attrs(%{tid: "profile-live-person"}, %{
          id: Euclid.Extra.List.only!(person.demographics).id,
          dob: nil,
          notes: nil,
          occupation: nil,
          employment: nil,
          marital_status: nil,
          ethnicity: nil,
          race: nil,
          sex_at_birth: nil,
          gender_identity: [],
          first_name: nil,
          last_name: nil,
          preferred_language: nil
        })

      {:ok, _} = Cases.update_person(person, {person_attrs, Test.Fixtures.audit_meta(user)})

      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "gender-identity", "Unknown")
      assert_role_text(page_live, "sex-at-birth", "Unknown")
      assert_role_text(page_live, "ethnicity", "Unknown")
      assert_role_text(page_live, "race", "Unknown")
      assert_role_text(page_live, "marital-status", "Unknown")
      assert_role_text(page_live, "employment", "Unknown")
      assert_role_text(page_live, "occupation", "Unknown")
      assert_role_text(page_live, "notes", "--")
      assert_role_text(page_live, "date-of-birth", "Unknown")
      assert_role_text(page_live, "full-name", "Unknown")
    end

    @tag :skip
    test "navigating to edit demographics", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      page_live
      |> element("[data-role=edit-demographics-button]")
      |> render_click()
      |> assert_redirects_to("/people/#{person.id}/edit-demographics")
    end
  end

  describe "ethnicity_value" do
    test "returns human readable ethnicity value for person" do
      %{ethnicity: %{major: "hispanic_latinx_or_spanish_origin"}}
      |> ProfileLive.ethnicity_value()
      |> assert_eq("Hispanic, Latino/a, or Spanish origin")

      %{ethnicity: %{major: "not_hispanic_latinx_or_spanish_origin"}}
      |> ProfileLive.ethnicity_value()
      |> assert_eq("Not Hispanic, Latino/a, or Spanish origin")

      %{ethnicity: %{major: "declined_to_answer"}} |> ProfileLive.ethnicity_value() |> assert_eq("Declined to answer")
      %{ethnicity: %{major: "unknown"}} |> ProfileLive.ethnicity_value() |> assert_eq("Unknown")
      %{ethnicity: %{major: nil}} |> ProfileLive.ethnicity_value() |> assert_eq("Unknown")
      %{ethnicity: nil} |> ProfileLive.ethnicity_value() |> assert_eq("Unknown")
    end
  end

  describe "detailed_ethnicities" do
    test "safely gets list of detailed ethnicities from person" do
      %{ethnicity: %{detailed: ["foo", "bar"]}} |> ProfileLive.detailed_ethnicities() |> assert_eq(["foo", "bar"])
      %{ethnicity: %{detailed: []}} |> ProfileLive.detailed_ethnicities() |> assert_eq([])
      %{ethnicity: %{detailed: nil}} |> ProfileLive.detailed_ethnicities() |> assert_eq([])
      %{ethnicity: nil} |> ProfileLive.detailed_ethnicities() |> assert_eq([])
    end
  end

  describe "archiving people" do
    test "displaying an archived person", %{conn: conn, user: user, person: sick_person} do
      view =
        Pages.Profile.visit(conn, sick_person)
        |> Pages.Profile.refute_archived_banner_is_visible()
        |> Pages.assert_element_triggers_confirmation_prompt(
          "archive",
          "Archive record? This record will no longer be editable and will not appear on the index case list, contacts list, nor in the search results."
        )
        |> Pages.Profile.click_archive_button()

      sick_person = Cases.get_person(sick_person.id, user)

      view
      |> assert_audit_logged_change(sick_person, user, "archive-person", "profile-archive-person")
      |> Pages.Profile.assert_archived_banner_is_visible(user.name, Format.date(sick_person.archived_at))
    end

    test "unarchiving a person", %{conn: conn, user: user, person: sick_person} do
      Cases.archive_person(sick_person.id, user, Test.Fixtures.admin_audit_meta())
      sick_person = Cases.get_person(sick_person.id, user)

      Pages.Profile.visit(conn, sick_person)
      |> Pages.Profile.assert_archived_banner_is_visible(user.name, Format.date(sick_person.archived_at))
      |> Pages.Profile.click_unarchive_person_button()
      |> Pages.Profile.refute_archived_banner_is_visible()
      |> assert_audit_logged_change(sick_person, user, "unarchive-person", "profile-unarchive-person")
    end

    defp assert_audit_logged_change(view, person, user, action, event) do
      assert_recent_audit_log(person, user, action: action, event: event)
      view
    end
  end

  defp create_case_investigation(person, user, tid, reported_on, attrs \\ %{}) do
    lab_result =
      Test.Fixtures.lab_result_attrs(person, user, "lab_result_#{tid}", reported_on, %{
        result: "positive",
        request_facility_name: "Big Big Hospital",
        reported_on: reported_on,
        sampled_on: ~D[2020-01-02],
        test_type: "PCR"
      })
      |> Cases.create_lab_result!()

    Test.Fixtures.case_investigation_attrs(
      person,
      lab_result,
      user,
      tid,
      %{name: "001"}
      |> Map.merge(attrs)
    )
    |> Cases.create_case_investigation!()
  end

  defp create_contact_investigation(user, sick_person, lab_result_attrs, case_investigation_attrs, contact_investigation_attrs) do
    lab_result =
      Test.Fixtures.lab_result_attrs(sick_person, user, "lab_result", ~D[2020-08-07], lab_result_attrs)
      |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(sick_person, lab_result, user, "the contagious person's case investigation", case_investigation_attrs)
      |> Cases.create_case_investigation!()

    {:ok, contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs(
         "contact_investigation",
         Map.put(contact_investigation_attrs, :exposing_case_id, case_investigation.id)
       ), Test.Fixtures.admin_audit_meta()}
      |> ContactInvestigations.create()

    contact_investigation
  end
end
