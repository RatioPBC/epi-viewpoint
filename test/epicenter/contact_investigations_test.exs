defmodule Epicenter.ContactInvestigationsTest do
  use Epicenter.DataCase, async: true

  import ExUnit.CaptureLog

  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias Epicenter.Test.AuditLogAssertions

  @admin Test.Fixtures.admin()

  describe "getting a contact investigation" do
    setup do
      person = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, @admin, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "investigation", %{})
        |> Cases.create_case_investigation!()

      {:ok, contact_investigation} =
        Test.Fixtures.contact_investigation_attrs("tid", %{exposing_case_id: case_investigation.id})
        |> Test.Fixtures.wrap_with_audit_meta()
        |> ContactInvestigations.create()

      [contact_investigation: contact_investigation]
    end

    test "records an audit log entry", %{contact_investigation: contact_investigation} do
      capture_log(fn -> ContactInvestigations.get(contact_investigation.id, @admin) end)
      |> AuditLogAssertions.assert_viewed_person(@admin, contact_investigation.exposed_person)
    end
  end
end
