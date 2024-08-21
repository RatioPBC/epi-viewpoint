defmodule EpiViewpoint.AuditLog.PhiLoggableTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.AuditLog.PhiLoggable
  alias EpiViewpoint.Cases
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "ContactInvestigation" do
    setup do
      person = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, @admin, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "investigation", %{})
        |> Cases.create_case_investigation!()

      {:ok, contact_investigation} =
        Test.Fixtures.contact_investigation_attrs("contact-investigation-tid", %{
          exposing_case_id: case_investigation.id
        })
        |> Test.Fixtures.wrap_with_audit_meta()
        |> ContactInvestigations.create()

      [contact_investigation: contact_investigation]
    end

    test "returns the exposed_person_id", %{contact_investigation: contact_investigation} do
      assert PhiLoggable.phi_identifier(contact_investigation) == contact_investigation.exposed_person_id
    end
  end

  describe "CaseInvestigation" do
    setup do
      person = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, @admin, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "investigation", %{})
        |> Cases.create_case_investigation!()

      [case_investigation: case_investigation]
    end

    test "returns the person_id", %{case_investigation: case_investigation} do
      assert PhiLoggable.phi_identifier(case_investigation) == case_investigation.person_id
    end
  end

  describe "Person" do
    setup do
      [person: Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()]
    end

    test "returns the person_id", %{person: person} do
      assert PhiLoggable.phi_identifier(person) == person.id
    end
  end

  describe "Place" do
    setup do
      [place: Test.Fixtures.place_attrs(@admin, "alice") |> Cases.create_place!()]
    end

    test "returns the place_id", %{place: place} do
      assert PhiLoggable.phi_identifier(place) == place.id
    end
  end
end
