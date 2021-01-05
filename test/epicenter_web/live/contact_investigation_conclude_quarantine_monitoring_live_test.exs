defmodule EpicenterWeb.ContactInvestigationConcludeQuarantineMonitoringLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "investigation", %{})
      |> Cases.create_case_investigation!()

    {:ok, contact_investigation} =
      Test.Fixtures.contact_investigation_attrs("tid", %{exposing_case_id: case_investigation.id})
      |> Test.Fixtures.wrap_with_audit_meta()
      |> ContactInvestigations.create()

    [contact_investigation: contact_investigation, case_investigation: case_investigation, person: person, user: user]
  end

  test "shows conclude quarantine monitoring form", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationConcludeQuarantineMonitoring.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationConcludeQuarantineMonitoring.assert_here()
    |> Pages.ContactInvestigationConcludeQuarantineMonitoring.assert_page_heading("Conclude quarantine monitoring")
    |> Pages.ContactInvestigationConcludeQuarantineMonitoring.assert_reasons_selection(%{
      "Successfully completed quarantine period" => false,
      "Person unable to quarantine" => false,
      "Refused to cooperate" => false,
      "Lost to follow up" => false,
      "Transferred to another jurisdiction" => false,
      "Deceased" => false
    })
  end
end
