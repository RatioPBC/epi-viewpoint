defmodule EpicenterWeb.ContactsLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup [:register_and_log_in_user, :create_contacts]

  describe "rendering" do
    test "user can visit the contacts page", %{conn: conn} do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_here()
    end

    test "People with exposures are listed", %{conn: conn, caroline: caroline, donald: donald} do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_table_contents([
        ["", "Name", "Viewpoint ID", "Exposure date", "Investigation status", "Assignee"],
        ["", "Caroline Testuser", caroline.id, "10/31/2020", "", "assignee"],
        ["", "Donald Testuser", donald.id, "10/31/2020", "", ""]
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
          ["Caroline Testuser", ""],
          ["Donald Testuser", "assignee"]
        ],
        columns: ["Name", "Assignee"]
      )
    end

    test "assignment updates broadcast to other browsers", %{assignee: assignee, donald: donald, conn: conn} do
      view_1 = Pages.Contacts.visit(conn)
      view_2 = Pages.Contacts.visit(conn)

      view_1
      |> Pages.Contacts.click_person_checkbox(person: donald, value: "on")
      |> Pages.Contacts.change_form(%{"user" => assignee.id})

      view_1
      |> Pages.Contacts.assert_table_contents(
        [
          ["Name", "Assignee"],
          ["Caroline Testuser", "assignee"],
          ["Donald Testuser", "assignee"]
        ],
        columns: ["Name", "Assignee"]
      )

      retry_until(fn ->
        view_2
        |> Pages.Contacts.assert_table_contents(
          [
            ["Name", "Assignee"],
            ["Caroline Testuser", "assignee"],
            ["Donald Testuser", "assignee"]
          ],
          columns: ["Name", "Assignee"]
        )
      end)
    end
  end

  defp create_contacts(%{user: user} = _context) do
    assignee = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "assignee") |> Accounts.register_user!()
    alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
    case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation") |> Cases.create_case_investigation!()

    {:ok, caroline_exposure} =
      {Test.Fixtures.exposure_attrs(case_investigation, "caroline_exposure"), Test.Fixtures.admin_audit_meta()} |> Cases.create_exposure()

    {:ok, donald_exposure} =
      {Test.Fixtures.exposure_attrs(case_investigation, "donald_exposure", %{
         exposed_person: %{tid: "donald", demographics: [%{first_name: "Donald", last_name: "Testuser"}]}
       }), Test.Fixtures.admin_audit_meta()}
      |> Cases.create_exposure()

    caroline_exposure = Cases.get_exposure(caroline_exposure.id) |> Cases.preload_exposed_person()
    donald_exposure = Cases.get_exposure(donald_exposure.id) |> Cases.preload_exposed_person()

    caroline = caroline_exposure.exposed_person
    donald = donald_exposure.exposed_person

    Cases.assign_user_to_people(user_id: assignee.id, people_ids: [caroline.id], audit_meta: Test.Fixtures.admin_audit_meta())

    [assignee: assignee, caroline: caroline, donald: donald, user: user]
  end
end
