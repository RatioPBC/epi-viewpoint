defmodule EpicenterWeb.ProfileLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.ProfileLive
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.preload_demographics()
    [person: person, user: user]
  end

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}")

    assert_has_role(disconnected_html, "profile-page")
    assert_has_role(page_live, "profile-page")
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
      :ok
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
      person |> ProfileLive.phone_numbers() |> assert_eq(["(111) 111-1001", "(111) 111-1000", "+1 (111) 111-1009"])
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

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_lab_results([
        ["Collection", "Result", "Ordering Facility", "Analysis", "Reported", "Type"],
        ["04/12/2020", "positive", "Big Big Hospital", "04/13/2020", "04/14/2020", "PCR"],
        ["04/10/2020", "positive", "Big Big Hospital", "04/11/2020", "04/12/2020", "PCR"]
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

  describe "case investigations" do
    defp build_case_investigation(person, user, tid, reported_on, attrs \\ %{}) do
      lab_result =
        Test.Fixtures.lab_result_attrs(person, user, "lab_result_#{tid}", reported_on, %{
          result: "positive",
          request_facility_name: "Big Big Hospital",
          reported_on: reported_on,
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

    test "it shows a pending case investigation", %{conn: conn, person: person, user: user} do
      build_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{status: "Pending", status_value: "pending", reported_on: "08/07/2020", number: "001"})
      |> Pages.Profile.refute_clinical_details_showing("001")
      |> Pages.Profile.refute_contacts_showing("001")
    end

    test "if lab result is missing reported_on, initiated date is unknown", %{conn: conn, person: person, user: user} do
      build_case_investigation(person, user, "case_investigation", nil)

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{status: "Pending", status_value: "pending", reported_on: "Unknown", number: "001"})
    end

    test "if there are no case investigations, don't  show a case investigation", %{conn: conn, person: person} do
      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_no_case_investigations()
    end

    test "starting a case investigation", %{conn: conn, person: person, user: user} do
      case_investigation = build_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

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

      build_case_investigation(person, user, "case_investigation", nil, %{
        discontinued_at: date,
        discontinue_reason: "Unable to reach"
      })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{status: "Discontinued", status_value: "discontinued", reported_on: "Unknown", number: "001"})
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
        build_case_investigation(person, user, "case_investigation", nil, %{
          discontinued_at: NaiveDateTime.utc_now(),
          discontinue_reason: "Unable to reach"
        })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.click_edit_discontinuation_link("001")
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/discontinue")
    end

    test "started case investigations say so", %{conn: conn, person: person, user: user} do
      build_case_investigation(person, user, "case_investigation", nil, %{started_at: NaiveDateTime.utc_now(), clinical_status: "symptomatic"})

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{status: "Ongoing interview", status_value: "started", reported_on: "Unknown", number: "001"})
      |> Pages.Profile.assert_clinical_details_showing("001", %{clinical_status: "Symptomatic"})
      |> Pages.Profile.assert_contacts_showing("001")
    end

    test "started case investigations that lack a clinical details show the values as 'None'", %{conn: conn, person: person, user: user} do
      build_case_investigation(person, user, "case_investigation", nil, %{
        started_at: NaiveDateTime.utc_now(),
        clinical_status: nil,
        symptom_onset_date: nil
      })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_clinical_details_showing("001", %{clinical_status: "None", symptom_onset_date: "None", symptoms: "None"})
    end

    test "started case investigations with a clinical details asymptomatic render correctly", %{conn: conn, person: person, user: user} do
      build_case_investigation(person, user, "case_investigation", nil, %{
        started_at: NaiveDateTime.utc_now(),
        clinical_status: "asymptomatic",
        symptom_onset_date: ~D[2020-09-12],
        symptoms: ["nasal_congestion", "Custom Symptom"]
      })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_clinical_details_showing("001", %{
        clinical_status: "Asymptomatic",
        symptom_onset_date: "09/12/2020",
        symptoms: "Nasal congestion, Custom Symptom"
      })
    end

    test "started case investigations with a unknown clinical details render correctly", %{conn: conn, person: person, user: user} do
      build_case_investigation(person, user, "case_investigation", nil, %{
        started_at: NaiveDateTime.utc_now(),
        clinical_status: "unknown"
      })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_clinical_details_showing("001", %{clinical_status: "Unknown"})
    end

    test "started case investigations with empty lists of symptoms show None for symptoms", %{conn: conn, person: person, user: user} do
      build_case_investigation(person, user, "case_investigation", nil, %{
        started_at: NaiveDateTime.utc_now(),
        symptoms: []
      })

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_clinical_details_showing("001", %{symptoms: "None"})
    end

    test "started case investigations can be completed", %{conn: conn, person: person, user: user} do
      build_case_investigation(person, user, "case_investigation", nil, %{started_at: NaiveDateTime.utc_now()})

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigation_complete_button_title("001", "Complete interview")
    end

    test "started case investigations show contacts", %{conn: conn, person: person, user: user} do
      case_investigation = build_case_investigation(person, user, "case_investigation", ~D[2020-08-07], %{started_at: NaiveDateTime.utc_now()})

      {:ok, _} =
        Cases.create_exposure(
          {%{
             exposing_case_id: case_investigation.id,
             relationship_to_case: "Family",
             most_recent_date_together: ~D[2020-10-31],
             household_member: true,
             under_18: true,
             guardian_name: "Jacob",
             guardian_phone: "(111) 111-1832",
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

      {:ok, _} =
        Cases.create_exposure(
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
                 }
               ]
             }
           }, Test.Fixtures.admin_audit_meta()}
        )

      {:ok, _} =
        Cases.create_exposure(
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

      assert [
               "Complete Testuser Family Household Minor Guardian: Jacob (111) 111-1832 Haitian Creole Last together 10/31/2020",
               "Adult Testuser Friend (111) 111-1542 Last together 11/30/2020",
               "Partial Testuser Friend Last together 11/30/2020"
             ] =
               Pages.Profile.visit(conn, person)
               |> Pages.Profile.assert_contacts_showing("001")
               |> Pages.Profile.case_investigation_contact_details("001")
    end

    test "a contact can be edited", %{conn: conn, person: person, user: user} do
      case_investigation = build_case_investigation(person, user, "case_investigation", ~D[2020-08-07], %{started_at: NaiveDateTime.utc_now()})

      {:ok, exposure} =
        Cases.create_exposure(
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
      |> Pages.Profile.click_edit_contact_link(exposure)
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/contact/#{exposure.id}")
    end

    test "a contact can be removed", %{conn: conn, person: person, user: user} do
      case_investigation = build_case_investigation(person, user, "case_investigation", ~D[2020-08-07], %{started_at: NaiveDateTime.utc_now()})

      {:ok, exposure} =
        Cases.create_exposure(
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
      view |> Pages.Profile.click_remove_contact_link(exposure)

      case_investigation = Cases.get_case_investigation(case_investigation.id) |> Cases.preload_exposures()
      assert case_investigation.exposures == []

      assert [] =
               view
               |> Pages.Profile.case_investigation_contact_details("001")
    end

    test "case investigations with completed interviews render correctly", %{conn: conn, person: person, user: user} do
      completed_at = ~U[2020-11-05 19:57:00Z]
      case_investigation = build_case_investigation(person, user, "case_investigation", nil, %{completed_interview_at: completed_at})

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_case_investigations(%{
        status: "Completed interview",
        status_value: "completed-interview",
        reported_on: "Unknown",
        number: "001"
      })
      |> Pages.Profile.assert_case_investigation_has_history("Completed interview on 11/05/2020 at 02:57pm EST")
      |> Pages.Profile.refute_complete_interview_button("001")
      |> Pages.Profile.click_edit_complete_interview_link("001")
      |> assert_redirects_to("/case-investigations/#{case_investigation.id}/complete-interview")
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

    test "assign_person", %{assignee: assignee, person: alice, user: user} do
      {:ok, [alice]} =
        Cases.assign_user_to_people(
          user_id: assignee.id,
          people_ids: [alice.id],
          audit_meta: Test.Fixtures.audit_meta(user)
        )

      updated_socket = %Phoenix.LiveView.Socket{assigns: %{person: alice}} |> ProfileLive.assign_person(alice)
      assert updated_socket.assigns.person.addresses |> tids() == ["address1"]
      assert updated_socket.assigns.person.assigned_to.tid == "assignee"
      assert updated_socket.assigns.person.lab_results |> tids() == ["lab1"]
      assert updated_socket.assigns.person.tid == "alice"
    end

    test "people can be assigned to users on index and show page, with cross-client updating", %{conn: conn, person: alice, assignee: assignee} do
      billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()

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
      assert Cases.get_person(alice.id) |> Cases.preload_assigned_to() |> Map.get(:assigned_to) |> Map.get(:tid) == "assignee"

      # "assignee" shows up on index page
      index_page_live
      |> table_contents(columns: ["Name", "Assignee"])
      |> assert_eq([
        ["Name", "Assignee"],
        ["Alice Testuser", "assignee"],
        ["Billy Testuser", ""]
      ])

      # unassign "assignee" via show page
      show_page_live |> element("#assignment-form") |> render_change(%{"user" => "-unassigned-"})
      assert_selected_dropdown_option(view: show_page_live, data_role: "users", expected: ["Unassigned"])
      assert Cases.get_person(alice.id) |> Cases.preload_assigned_to() |> Map.get(:assigned_to) == nil

      # "assignee" disappears from index page
      index_page_live
      |> table_contents(columns: ["Name", "Assignee"])
      |> assert_eq([
        ["Name", "Assignee"],
        ["Alice Testuser", ""],
        ["Billy Testuser", ""]
      ])

      # choose "assignee" via index page
      index_page_live |> element("[data-tid=#{alice.tid}]") |> render_click(%{"person-id" => alice.id, "value" => "on"})
      index_page_live |> element("[data-tid=#{billy.tid}]") |> render_click(%{"person-id" => billy.id, "value" => "on"})
      index_page_live |> element("#assignment-form") |> render_change(%{"user" => assignee.id})

      assert_selected_dropdown_option(view: show_page_live, data_role: "users", expected: ["assignee"])
    end

    test "handles assign_users message when the changed people include the current person", %{person: alice, assignee: assignee} do
      billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()
      socket = %Phoenix.LiveView.Socket{assigns: %{person: alice}}

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
      socket = %Phoenix.LiveView.Socket{assigns: %{person: alice}}
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
      assert_role_text(page_live, "race", "Filipino")
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
end
