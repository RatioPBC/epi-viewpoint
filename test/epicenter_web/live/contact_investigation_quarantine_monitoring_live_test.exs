defmodule EpicenterWeb.ContactInvestigationQuarantineMonitoringLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
    case_investigation = Test.Fixtures.case_investigation_attrs(person, lab_result, user, "investigation") |> Cases.create_case_investigation!()

    {:ok, contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs("contact_investigation", %{
         exposing_case_id: case_investigation.id,
         exposed_on: ~D[2019-12-31],
         interview_completed_at: ~U[2020-01-01 23:03:07Z],
         interview_started_at: ~U[2020-01-01 22:03:07Z]
       }), Test.Fixtures.admin_audit_meta()}
      |> Cases.create_contact_investigation()

    [contact_investigation: contact_investigation, user: user]
  end

  test "shows quarantine monitoring page", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationQuarantineMonitoring.assert_here()
  end

  test "prefills start date with exposure date", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationQuarantineMonitoring.assert_here()
    |> Pages.ContactInvestigationQuarantineMonitoring.assert_quarantine_date_started("12/31/2019", "Exposure date: 12/31/2019")
    |> Pages.ContactInvestigationQuarantineMonitoring.assert_quarantine_recommended_length("Recommended length: 14 days")
  end
end