defmodule Epicenter.ContactInvestigationsTest do
  use Epicenter.DataCase, async: true

  import ExUnit.CaptureLog

  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias Epicenter.Test.AuditLogAssertions

  @admin Test.Fixtures.admin()

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

    other_case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "person1_case_investigation", %{})
      |> Cases.create_case_investigation!()

    {:ok, other_contact_investigation} =
      ContactInvestigations.create({
        Test.Fixtures.contact_investigation_attrs("contact_investigation", %{exposing_case_id: other_case_investigation.id})
        |> Map.put(:exposed_person, %{
          demographics: [
            %{first_name: "Cindy"}
          ],
          phones: [
            %{number: "1111111987"}
          ]
        }),
        Test.Fixtures.admin_audit_meta()
      })

    [
      contact_investigation: contact_investigation,
      case_investigation: case_investigation,
      other_contact_investigation: other_contact_investigation,
      other_case_investigation: other_case_investigation
    ]
  end

  describe "getting a contact investigation" do
    test "records an audit log entry", %{contact_investigation: contact_investigation} do
      capture_log(fn -> ContactInvestigations.get(contact_investigation.id, @admin) end)
      |> AuditLogAssertions.assert_viewed_person(@admin, contact_investigation.exposed_person)
    end
  end

  describe "preloading an exposing case investigation" do
    test "records an audit log entry for the person on the case investigation", %{
      contact_investigation: contact_investigation,
      case_investigation: case_investigation
    } do
      case_investigation = case_investigation |> Cases.preload_person()

      capture_log(fn -> contact_investigation |> ContactInvestigations.preload_exposing_case(@admin) end)
      |> AuditLogAssertions.assert_viewed_person(@admin, case_investigation.person)
    end

    test "records an audit log entry for the person on the case investigation with multiple contact investigations", %{
      contact_investigation: contact_investigation,
      case_investigation: case_investigation,
      other_contact_investigation: other_contact_investigation,
      other_case_investigation: other_case_investigation
    } do
      case_investigation = case_investigation |> Cases.preload_person()
      other_case_investigation = other_case_investigation |> Cases.preload_person()

      capture_log(fn -> [contact_investigation, other_contact_investigation] |> ContactInvestigations.preload_exposing_case(@admin) end)
      |> AuditLogAssertions.assert_viewed_person(@admin, case_investigation.person)
      |> AuditLogAssertions.assert_viewed_person(@admin, other_case_investigation.person)
    end

    test "does not record an audit log entry when passed nil" do
      assert capture_log(fn -> ContactInvestigations.preload_exposing_case(nil, @admin) end) == ""
    end
  end
end
