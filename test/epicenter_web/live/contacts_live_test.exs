defmodule EpicenterWeb.ContactsLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup [:register_and_log_in_user, :create_contacts]

  describe "rendering" do
    test "user can visit the contacts page", %{conn: conn} do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_here()
    end

    test "People with  exposures are listed", %{conn: conn, exposure: exposure} do
      Pages.Contacts.visit(conn)
      |> Pages.Contacts.assert_table_contents([
        ["", "Name", "Viewpoint ID", "Exposure date", "Investigation status", "Assignee"],
        ["", "Caroline Testuser", exposure.exposed_person.id, "10/31/2020", "", ""]
      ])
    end
  end

  defp create_contacts(%{user: user} = _context) do
    alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(alice, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
    case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, user, "investigation") |> Cases.create_case_investigation!()
    {:ok, exposure} = {Test.Fixtures.exposure_attrs(case_investigation, "exposure"), Test.Fixtures.admin_audit_meta()} |> Cases.create_exposure()
    exposure = Cases.get_exposure(exposure.id) |> Cases.preload_exposed_person()
    [user: user, exposure: exposure]
  end
end
