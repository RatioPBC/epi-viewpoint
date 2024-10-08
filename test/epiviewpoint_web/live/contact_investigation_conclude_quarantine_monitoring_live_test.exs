defmodule EpiViewpointWeb.ContactInvestigationConcludeQuarantineMonitoringLiveTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Cases
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

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

  test "records an audit log entry", %{conn: conn, contact_investigation: contact_investigation, user: user} do
    AuditLogAssertions.expect_phi_view_logs(2)
    Pages.ContactInvestigationConcludeQuarantineMonitoring.visit(conn, contact_investigation)
    AuditLogAssertions.verify_phi_view_logged(user, contact_investigation.exposed_person)
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

  test "prefills the form if there is already a reason on the contact investigation", %{conn: conn, contact_investigation: contact_investigation} do
    {:ok, _} =
      ContactInvestigations.update(
        contact_investigation,
        {%{quarantine_conclusion_reason: "successfully_completed_quarantine", quarantine_concluded_at: ~U[2020-10-31 10:30:00Z]},
         Test.Fixtures.admin_audit_meta()}
      )

    Pages.ContactInvestigationConcludeQuarantineMonitoring.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationConcludeQuarantineMonitoring.assert_page_heading("Edit conclude quarantine monitoring")
    |> Pages.ContactInvestigationConcludeQuarantineMonitoring.assert_reasons_selection(%{
      "Successfully completed quarantine period" => true,
      "Person unable to quarantine" => false,
      "Refused to cooperate" => false,
      "Lost to follow up" => false,
      "Transferred to another jurisdiction" => false,
      "Deceased" => false
    })
  end

  test "saving quarantine conclusion reason for a contact investigation", %{
    conn: conn,
    contact_investigation: contact_investigation,
    user: user
  } do
    Pages.ContactInvestigationConcludeQuarantineMonitoring.visit(conn, contact_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-conclude-quarantine-monitoring-form",
      conclude_quarantine_monitoring_form: %{
        "reason" => "successfully_completed_quarantine"
      }
    )
    |> Pages.Profile.assert_here(contact_investigation.exposed_person)

    contact_investigation = ContactInvestigations.get(contact_investigation.id, user)
    assert "successfully_completed_quarantine" == contact_investigation.quarantine_conclusion_reason
    assert ~U[2020-10-31 10:30:00Z] == contact_investigation.quarantine_concluded_at

    assert_recent_audit_log(contact_investigation, user,
      action: "update-contact-investigation",
      event: "conclude-contact-investigation-quarantine-monitoring"
    )
  end

  test "editing a quarantine conclusion reason does not change the existing quarantine_concluded_at timestamp", %{
    conn: conn,
    contact_investigation: contact_investigation,
    user: user
  } do
    {:ok, _} =
      ContactInvestigations.update(
        contact_investigation,
        {%{quarantine_conclusion_reason: "successfully_completed_quarantine", quarantine_concluded_at: ~U[2020-10-05 19:57:00Z]},
         Test.Fixtures.admin_audit_meta()}
      )

    Pages.ContactInvestigationConcludeQuarantineMonitoring.visit(conn, contact_investigation)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-conclude-quarantine-monitoring-form",
      conclude_quarantine_monitoring_form: %{
        "reason" => "deceased"
      }
    )
    |> Pages.Profile.assert_here(contact_investigation.exposed_person)

    assert_recent_audit_log(contact_investigation, user,
      action: "update-contact-investigation",
      event: "conclude-contact-investigation-quarantine-monitoring"
    )

    contact_investigation = ContactInvestigations.get(contact_investigation.id, user)
    assert "deceased" == contact_investigation.quarantine_conclusion_reason
    assert ~U[2020-10-05 19:57:00Z] == contact_investigation.quarantine_concluded_at
  end

  describe "validations" do
    test "saving without a selected reason shows an error", %{
      conn: conn,
      contact_investigation: contact_investigation
    } do
      Pages.ContactInvestigationConcludeQuarantineMonitoring.visit(conn, contact_investigation)
      |> Pages.submit_live("#contact-investigation-conclude-quarantine-monitoring-form",
        conclude_quarantine_monitoring_form: %{}
      )
      |> Pages.assert_validation_messages(%{
        "conclude_quarantine_monitoring_form[reason]" => "can't be blank"
      })

      assert_revision_count(contact_investigation, 1)
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationConcludeQuarantineMonitoring.visit(conn, contact_investigation)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes something", %{conn: conn, contact_investigation: contact_investigation} do
      view =
        Pages.ContactInvestigationConcludeQuarantineMonitoring.visit(conn, contact_investigation)
        |> Pages.ContactInvestigationConcludeQuarantineMonitoring.change_form(conclude_quarantine_monitoring_form: %{"reason" => "deceased"})
        |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")

      assert %{"conclude_quarantine_monitoring_form[reason]" => "deceased"} = Pages.form_state(view)
    end
  end
end
