defmodule EpicenterWeb.ContactsLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup [:register_and_log_in_user, :create_contacts]

  describe "rendering" do
    test "user can visit the contacts page", %{conn: conn} do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_here()
    end

    test "records an audit log entry for each person on the page", %{user: user, bob: bob, caroline: caroline, donald: donald, conn: conn} do
      capture_log(fn -> Pages.Contacts.visit(conn) end)
      |> AuditLogAssertions.assert_viewed_people(user, [bob, caroline, donald])
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

  describe "assigning case investigator to a contact" do
    test "case investigator can be unassigned and assigned to contacts", %{assignee: assignee, caroline: caroline, donald: donald, conn: conn} do
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

      Cases.get_people([caroline.id])
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

    Cases.assign_user_to_people(user_id: assignee.id, people_ids: [caroline.id], audit_meta: Test.Fixtures.admin_audit_meta())

    [assignee: assignee, bob: bob, caroline: caroline, donald: donald, user: user]
  end
end
