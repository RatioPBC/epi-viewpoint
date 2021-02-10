defmodule Epicenter.ContactInvestigationsTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias Epicenter.Test.AuditLogAssertions

  @admin Test.Fixtures.admin()

  describe "getting a contact investigation" do
    setup [:setup_contact_investigations]

    test "records an audit log entry", %{contact_investigation: contact_investigation} do
      AuditLogAssertions.expect_phi_view_logs(1)
      ContactInvestigations.get(contact_investigation.id, @admin)
      AuditLogAssertions.verify_phi_view_logged(@admin, contact_investigation.exposed_person)
    end
  end

  describe "preloading an exposing case investigation" do
    setup [:setup_contact_investigations]

    test "records an audit log entry for the person on the case investigation", %{
      contact_investigation: contact_investigation,
      case_investigation: case_investigation
    } do
      case_investigation = case_investigation |> Cases.preload_person()
      AuditLogAssertions.expect_phi_view_logs(1)
      contact_investigation |> ContactInvestigations.preload_exposing_case(@admin)
      AuditLogAssertions.verify_phi_view_logged(@admin, case_investigation.person)
    end

    test "records an audit log entry for the person on the case investigation with multiple contact investigations", %{
      contact_investigation: contact_investigation,
      case_investigation: case_investigation,
      other_contact_investigation: other_contact_investigation,
      other_case_investigation: other_case_investigation
    } do
      case_investigation = case_investigation |> Cases.preload_person()
      other_case_investigation = other_case_investigation |> Cases.preload_person()

      AuditLogAssertions.expect_phi_view_logs(2)

      [contact_investigation, other_contact_investigation]
      |> ContactInvestigations.preload_exposing_case(@admin)

      AuditLogAssertions.verify_phi_view_logged(@admin, [case_investigation.person, other_case_investigation.person])
    end

    test "does not record an audit log entry when passed nil" do
      unique_user = @admin |> Map.put(:id, Ecto.UUID.generate())

      AuditLogAssertions.expect_phi_view_logs(0)
      ContactInvestigations.preload_exposing_case(nil, unique_user)
    end
  end

  describe "list_exposed_people" do
    setup [:persist_admin]

    setup do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      [user: user]
    end

    defp create_contact_investigation(user, exposing_person_tid, exposed_person_tid) do
      exposing_person = Test.Fixtures.person_attrs(user, exposing_person_tid) |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(exposing_person, user, "lab-result", ~D[2020-10-27]) |> Cases.create_lab_result!()
      case_investigation = Test.Fixtures.case_investigation_attrs(exposing_person, lab_result, user, "case") |> Cases.create_case_investigation!()
      {exposed_person_attrs, _meta} = Test.Fixtures.person_attrs(user, exposed_person_tid)

      {:ok, contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("#{exposed_person_tid}-contact-investigation",
           exposing_case_id: case_investigation.id,
           exposed_person: exposed_person_attrs
         ), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      exposed_person = contact_investigation |> Repo.preload(:exposed_person) |> Map.get(:exposed_person)
      {contact_investigation, exposed_person}
    end

    test "returns exposed people", %{user: user} do
      create_contact_investigation(user, "exposing", "exposed-1")
      create_contact_investigation(user, "exposing", "exposed-2")

      ContactInvestigations.list_exposed_people(:with_contact_investigation, @admin, reject_archived_people: true)
      |> tids()
      |> assert_eq(~w{exposed-1 exposed-2}, ignore_order: true)
    end

    test "records audit log for viewed people", %{user: user} do
      {_, exposed_person} = create_contact_investigation(user, "exposing", "exposed")

      AuditLogAssertions.expect_phi_view_logs(1)
      ContactInvestigations.list_exposed_people(:with_contact_investigation, @admin, reject_archived_people: true)
      AuditLogAssertions.verify_phi_view_logged(@admin, [exposed_person])
    end

    test "can optionally show archived people", %{user: user} do
      create_contact_investigation(user, "exposing", "not-archived")
      {_, archived_person} = create_contact_investigation(user, "exposing", "archived")
      Cases.archive_person(archived_person.id, user, Test.Fixtures.admin_audit_meta())

      ContactInvestigations.list_exposed_people(:with_contact_investigation, @admin, reject_archived_people: false)
      |> tids()
      |> assert_eq(~w{archived not-archived}, ignore_order: true)

      ContactInvestigations.list_exposed_people(:with_contact_investigation, @admin, reject_archived_people: true)
      |> tids()
      |> assert_eq(~w{not-archived}, ignore_order: true)
    end
  end

  defp setup_contact_investigations(_context) do
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
end
