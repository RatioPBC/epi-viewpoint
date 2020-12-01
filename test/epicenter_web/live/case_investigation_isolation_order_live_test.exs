defmodule EpicenterWeb.CaseInvestigationIsolationOrderLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "investigation", %{
        interview_completed_at: ~N[2020-01-01 23:03:07],
        isolation_monitoring_ended_on: ~D[2020-11-15],
        isolation_monitoring_started_on: ~D[2020-11-05],
        symptom_onset_on: ~D[2020-11-03]
      })
      |> Cases.create_case_investigation!()

    [case_investigation: case_investigation, person: person, user: user]
  end

  test "shows isolation order form", %{conn: conn, case_investigation: case_investigation} do
    Pages.CaseInvestigationIsolationOrder.visit(conn, case_investigation)
    |> Pages.CaseInvestigationIsolationOrder.assert_here()
    |> Pages.CaseInvestigationIsolationOrder.assert_page_heading("Edit isolation details")
  end

  test "saving isolation monitoring dates for a case investigation", %{conn: conn, case_investigation: case_investigation, person: person, user: user} do
    Pages.CaseInvestigationIsolationOrder.visit(conn, case_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#case-investigation-isolation-order-form",
      isolation_order_form: %{
        "order_sent_on" => "08/01/2020",
        "clearance_order_sent_on" => "08/11/2020"
      }
    )
    |> Pages.Profile.assert_here(person)

    assert_recent_audit_log(case_investigation, user, action: "update-case-investigation", event: "edit-case-investigation-isolation-order")
    case_investigation = Cases.get_case_investigation(case_investigation.id)
    assert ~D[2020-08-01] == case_investigation.isolation_order_sent_on
    assert ~D[2020-08-11] == case_investigation.isolation_clearance_order_sent_on
  end

  test "prefills dates if present", %{conn: conn, case_investigation: case_investigation} do
    {:ok, _} =
      Cases.update_case_investigation(
        case_investigation,
        {%{isolation_clearance_order_sent_on: ~D[2020-11-11], isolation_order_sent_on: ~D[2020-11-01]}, Test.Fixtures.admin_audit_meta()}
      )

    Pages.CaseInvestigationIsolationOrder.visit(conn, case_investigation)
    |> Pages.CaseInvestigationIsolationOrder.assert_page_heading("Edit isolation details")
    |> Pages.CaseInvestigationIsolationOrder.assert_isolation_order_sent_on("11/01/2020")
    |> Pages.CaseInvestigationIsolationOrder.assert_isolation_clearance_order_sent_on("11/11/2020")
  end

  describe "validations" do
    test "shows the errors for invalid dates", %{conn: conn, case_investigation: case_investigation} do
      Pages.CaseInvestigationIsolationOrder.visit(conn, case_investigation)
      |> Pages.submit_live("#case-investigation-isolation-order-form",
        isolation_order_form: %{
          "order_sent_on" => "02/31/2020",
          "clearance_order_sent_on" => "09/32/2020"
        }
      )
      |> Pages.assert_validation_messages(%{
        "isolation_order_form_order_sent_on" => "must be a valid MM/DD/YYYY date",
        "isolation_order_form_clearance_order_sent_on" => "must be a valid MM/DD/YYYY date"
      })
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, case_investigation: case_investigation} do
      assert Pages.CaseInvestigationIsolationOrder.visit(conn, case_investigation)
             |> Pages.navigation_confirmation_prompt()
             |> Euclid.Exists.blank?()
    end

    test "when the user changes something", %{conn: conn, case_investigation: case_investigation} do
      assert "Your updates have not been saved. Discard updates?" =
               Pages.CaseInvestigationIsolationOrder.visit(conn, case_investigation)
               |> Pages.CaseInvestigationIsolationOrder.change_form(isolation_order_form: %{"order_clearance_date" => "09/06/2020"})
               |> Pages.navigation_confirmation_prompt()
    end
  end
end
