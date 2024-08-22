defmodule EpiViewpointWeb.ContactsLiveTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

  setup [:register_and_log_in_user, :create_contacts]

  describe "rendering" do
    test "user can visit the contacts page", %{conn: conn} do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_here()
    end

    test "records an audit log entry for each person on the page", %{user: user, bob: bob, caroline: caroline, donald: donald, conn: conn} do
      AuditLogAssertions.expect_phi_view_logs(18)
      Pages.Contacts.visit(conn)
      AuditLogAssertions.verify_phi_view_logged(user, [bob, caroline, donald])
    end

    test "People with contact investigations are listed", %{conn: conn, bob: bob, caroline: caroline, donald: donald} do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_table_contents([
        ["", "Name", "Viewpoint ID", "Exposure date", "Investigation status", "Assignee"],
        ["", "Bob Testuser", bob.id, "10/31/2020", "Ongoing monitoring (11 days remaining)", ""],
        ["", "Caroline Testuser", caroline.id, "10/31/2020", "Pending interview", "assignee"],
        ["", "Donald Testuser", donald.id, "10/31/2020", "Discontinued", ""]
      ])
    end

    test "can visit an individual exposed person", %{conn: conn, caroline: caroline} do
      response =
        Pages.Contacts.visit(conn)
        |> Pages.Contacts.click_to_person_profile(caroline)

      caroline_id = caroline.id
      assert {:error, {:live_redirect, %{to: "/people/" <> ^caroline_id}}} = response
    end
  end

  describe "archiving people" do
    test "person can be archived", %{conn: conn, bob: bob, caroline: caroline, donald: donald} do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_archive_button_disabled()
      |> Pages.Contacts.assert_table_contents([
        ["", "Name", "Viewpoint ID", "Exposure date", "Investigation status", "Assignee"],
        ["", "Bob Testuser", bob.id, "10/31/2020", "Ongoing monitoring (11 days remaining)", ""],
        ["", "Caroline Testuser", caroline.id, "10/31/2020", "Pending interview", "assignee"],
        ["", "Donald Testuser", donald.id, "10/31/2020", "Discontinued", ""]
      ])
      |> Pages.Contacts.assert_unchecked("[data-tid=#{bob.tid}]")
      |> Pages.Contacts.click_person_checkbox(person: bob, value: "on")
      |> Pages.Contacts.assert_checked("[data-tid=#{bob.tid}]")
      |> Pages.assert_element_triggers_confirmation_prompt("archive-button", "Are you sure you want to archive 1 person(s)?")
      |> Pages.Contacts.click_archive()
      |> Pages.Contacts.assert_table_contents([
        ["", "Name", "Viewpoint ID", "Exposure date", "Investigation status", "Assignee"],
        ["", "Caroline Testuser", caroline.id, "10/31/2020", "Pending interview", "assignee"],
        ["", "Donald Testuser", donald.id, "10/31/2020", "Discontinued", ""]
      ])
      |> Pages.Contacts.assert_assignment_dropdown_disabled()
      |> Pages.Contacts.assert_archive_button_disabled()
    end
  end

  describe "filtering" do
    setup %{conn: conn, user: user, bob: bob, caroline: caroline, donald: donald} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
      case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation") |> Cases.create_case_investigation!()

      {:ok, ernst_contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("ernst_contact_investigation", %{
           exposing_case_id: case_investigation.id,
           interview_completed_at: ~U[2020-10-31 23:03:07Z],
           interview_started_at: ~U[2020-10-31 22:03:07Z],
           exposed_person: %{tid: "ernst", demographics: [%{first_name: "Ernst", last_name: "Testuser"}]}
         }), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      {:ok, frank_contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("ernst_contact_investigation", %{
           exposing_case_id: case_investigation.id,
           interview_completed_at: ~U[2020-10-31 23:03:07Z],
           interview_started_at: ~U[2020-10-31 22:03:07Z],
           quarantine_concluded_at: ~U[2020-10-31 10:30:00Z],
           quarantine_monitoring_ends_on: ~D[2020-11-13],
           quarantine_monitoring_starts_on: ~D[2020-11-03],
           exposed_person: %{tid: "frank", demographics: [%{first_name: "Frank", last_name: "Testuser"}]}
         }), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      {:ok, george_contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("george_contact_investigation", %{
           exposing_case_id: case_investigation.id,
           interview_started_at: ~U[2020-10-31 23:03:07Z],
           exposed_person: %{tid: "george", demographics: [%{first_name: "George", last_name: "Testuser"}]}
         }), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      ernst_contact_investigation = ContactInvestigations.get(ernst_contact_investigation.id, user) |> ContactInvestigations.preload_exposed_person()

      frank_contact_investigation = ContactInvestigations.get(frank_contact_investigation.id, user) |> ContactInvestigations.preload_exposed_person()

      george_contact_investigation =
        ContactInvestigations.get(george_contact_investigation.id, user) |> ContactInvestigations.preload_exposed_person()

      ernst = ernst_contact_investigation.exposed_person
      frank = frank_contact_investigation.exposed_person
      george = george_contact_investigation.exposed_person

      view =
        Pages.Contacts.visit(conn)
        |> Pages.Contacts.assert_table_contents(
          [
            ["Name", "Investigation status"],
            ["Bob Testuser", "Ongoing monitoring (11 days remaining)"],
            ["Caroline Testuser", "Pending interview"],
            ["Donald Testuser", "Discontinued"],
            ["Ernst Testuser", "Pending monitoring"],
            ["Frank Testuser", "Concluded monitoring"],
            ["George Testuser", "Ongoing interview"]
          ],
          columns: ["Name", "Investigation status"]
        )

      [view: view, bob: bob, caroline: caroline, donald: donald, ernst: ernst, frank: frank, george: george]
    end

    test "users can filter contacts by pending interview status", %{view: view} do
      view
      |> Pages.Contacts.assert_filter_selected(:all)
      |> Pages.Contacts.select_filter(:with_pending_interview)
      |> Pages.Contacts.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Caroline Testuser", "Pending interview"]
        ],
        columns: ["Name", "Investigation status"]
      )
    end

    test "users can filter contacts by ongoing interview status", %{view: view} do
      view
      |> Pages.Contacts.assert_filter_selected(:all)
      |> Pages.Contacts.select_filter(:with_ongoing_interview)
      |> Pages.Contacts.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["George Testuser", "Ongoing interview"]
        ],
        columns: ["Name", "Investigation status"]
      )
    end

    test "users can filter contacts by people who are pending or ongoing quarantine monitoring", %{view: view} do
      view
      |> Pages.Contacts.assert_filter_selected(:all)
      |> Pages.Contacts.select_filter(:with_quarantine_monitoring)
      |> Pages.Contacts.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Bob Testuser", "Ongoing monitoring (11 days remaining)"],
          ["Ernst Testuser", "Pending monitoring"]
        ],
        columns: ["Name", "Investigation status"]
      )
    end

    test "users can unfilter contacts using the all button", %{view: view} do
      view
      |> Pages.Contacts.select_filter(:with_quarantine_monitoring)
      |> Pages.Contacts.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Bob Testuser", "Ongoing monitoring (11 days remaining)"],
          ["Ernst Testuser", "Pending monitoring"]
        ],
        columns: ["Name", "Investigation status"]
      )
      |> Pages.Contacts.select_filter(:all)
      |> Pages.Contacts.assert_table_contents(
        [
          ["Name", "Investigation status"],
          ["Bob Testuser", "Ongoing monitoring (11 days remaining)"],
          ["Caroline Testuser", "Pending interview"],
          ["Donald Testuser", "Discontinued"],
          ["Ernst Testuser", "Pending monitoring"],
          ["Frank Testuser", "Concluded monitoring"],
          ["George Testuser", "Ongoing interview"]
        ],
        columns: ["Name", "Investigation status"]
      )
      |> Pages.Contacts.assert_filter_selected(:all)
    end
  end

  describe "assigning case investigator to a contact" do
    test "case investigator can be unassigned and assigned to contacts", %{
      assignee: assignee,
      caroline: caroline,
      donald: donald,
      conn: conn,
      user: user
    } do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_table_contents(
        [
          ["Name", "Assignee"],
          ["Bob Testuser", ""],
          ["Caroline Testuser", "assignee"],
          ["Donald Testuser", ""]
        ],
        columns: ["Name", "Assignee"]
      )
      |> Pages.Contacts.assert_assign_dropdown_options(data_role: "users", expected: ["", "Unassigned", "assignee", "fixture admin", "user"])
      |> Pages.Contacts.assert_unchecked("[data-tid=#{caroline.tid}]")
      |> Pages.Contacts.click_person_checkbox(person: caroline, value: "on")
      |> Pages.Contacts.assert_checked("[data-tid=#{caroline.tid}]")
      |> Pages.Contacts.change_form(%{"user" => "-unassigned-"})
      |> Pages.Contacts.assert_unchecked("[data-tid=#{caroline.tid}]")
      |> Pages.Contacts.assert_table_contents(
        [
          ["Name", "Assignee"],
          ["Bob Testuser", ""],
          ["Caroline Testuser", ""],
          ["Donald Testuser", ""]
        ],
        columns: ["Name", "Assignee"]
      )

      Cases.get_people([caroline.id], user)
      |> Cases.preload_assigned_to()
      |> Euclid.Extra.Enum.pluck(:assigned_to)
      |> assert_eq([nil])

      Pages.Contacts.visit(conn)
      |> Pages.Contacts.click_person_checkbox(person: donald, value: "on")
      |> Pages.Contacts.assert_checked("[data-tid=#{donald.tid}]")
      |> Pages.Contacts.change_form(%{"user" => assignee.id})
      |> Pages.Contacts.assert_unchecked("[data-tid=#{donald.tid}]")
      |> Pages.Contacts.assert_table_contents(
        [
          ["Name", "Assignee"],
          ["Bob Testuser", ""],
          ["Caroline Testuser", ""],
          ["Donald Testuser", "assignee"]
        ],
        columns: ["Name", "Assignee"]
      )
    end
  end

  defp create_contacts(%{user: user} = _context) do
    assignee = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "assignee") |> Accounts.register_user!()
    alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
    case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation") |> Cases.create_case_investigation!()

    {:ok, bob_contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs("bob_contact_investigation", %{
         exposing_case_id: case_investigation.id,
         interview_completed_at: ~U[2020-10-31 23:03:07Z],
         quarantine_monitoring_starts_on: ~D[2020-10-29],
         quarantine_monitoring_ends_on: ~D[2020-11-11],
         exposed_person: %{tid: "bob", demographics: [%{first_name: "Bob", last_name: "Testuser"}]}
       }), Test.Fixtures.admin_audit_meta()}
      |> ContactInvestigations.create()

    {:ok, caroline_contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs("caroline_contact_investigation", %{exposing_case_id: case_investigation.id}),
       Test.Fixtures.admin_audit_meta()}
      |> ContactInvestigations.create()

    {:ok, donald_contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs("donald_contact_investigation", %{
         exposing_case_id: case_investigation.id,
         interview_discontinued_at: ~U[2020-01-01 12:00:00Z],
         exposed_person: %{tid: "donald", demographics: [%{first_name: "Donald", last_name: "Testuser"}]}
       }), Test.Fixtures.admin_audit_meta()}
      |> ContactInvestigations.create()

    bob_contact_investigation = ContactInvestigations.get(bob_contact_investigation.id, user) |> ContactInvestigations.preload_exposed_person()

    caroline_contact_investigation =
      ContactInvestigations.get(caroline_contact_investigation.id, user) |> ContactInvestigations.preload_exposed_person()

    donald_contact_investigation = ContactInvestigations.get(donald_contact_investigation.id, user) |> ContactInvestigations.preload_exposed_person()

    bob = bob_contact_investigation.exposed_person
    caroline = caroline_contact_investigation.exposed_person
    donald = donald_contact_investigation.exposed_person

    Cases.assign_user_to_people(user_id: assignee.id, people_ids: [caroline.id], audit_meta: Test.Fixtures.admin_audit_meta(), current_user: user)

    [assignee: assignee, bob: bob, caroline: caroline, donald: donald, user: user]
  end
end
