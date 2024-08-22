defmodule EpiViewpointWeb.ContactInvestigationQuarantineMonitoringLiveTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Cases
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

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
      |> ContactInvestigations.create()

    exposed_person = ContactInvestigations.preload_exposed_person(contact_investigation) |> Map.get(:exposed_person)

    [contact_investigation: contact_investigation, exposed_person: exposed_person, user: user]
  end

  test "records an audit log entry", %{conn: conn, contact_investigation: contact_investigation, user: user} do
    AuditLogAssertions.expect_phi_view_logs(2)
    Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
    AuditLogAssertions.verify_phi_view_logged(user, contact_investigation.exposed_person)
  end

  test "shows quarantine monitoring page", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationQuarantineMonitoring.assert_here()
  end

  describe "without saved quarantine monitoring dates" do
    test "has add title", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
      |> Pages.ContactInvestigationQuarantineMonitoring.assert_page_title("Add quarantine dates")
    end

    test "prefills start date with exposure date", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
      |> Pages.ContactInvestigationQuarantineMonitoring.assert_here()
      |> Pages.ContactInvestigationQuarantineMonitoring.assert_quarantine_date_started("12/31/2019", "Exposure date: 12/31/2019")
      |> Pages.ContactInvestigationQuarantineMonitoring.assert_quarantine_recommended_length("Recommended length: 14 days")
    end
  end

  describe "with saved quarantine monitoring dates" do
    setup %{contact_investigation: contact_investigation} do
      {:ok, _} =
        ContactInvestigations.update(
          contact_investigation,
          {%{quarantine_monitoring_starts_on: ~D[2020-11-01], quarantine_monitoring_ends_on: ~D[2020-11-15]}, Test.Fixtures.admin_audit_meta()}
        )

      :ok
    end

    test "has edit title", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
      |> Pages.ContactInvestigationQuarantineMonitoring.assert_page_title("Edit quarantine dates")
    end

    test "prefills with saved quarantine monitoring dates", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
      |> Pages.ContactInvestigationQuarantineMonitoring.assert_here()
      |> Pages.ContactInvestigationQuarantineMonitoring.assert_quarantine_date_started("11/01/2020", "Exposure date: 12/31/2019")
      |> Pages.ContactInvestigationQuarantineMonitoring.assert_quarantine_date_ended("11/15/2020")
    end
  end

  test "saving quarantine monitoring dates", %{conn: conn, contact_investigation: contact_investigation, exposed_person: exposed_person, user: user} do
    Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationQuarantineMonitoring.assert_here()
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-quarantine-monitoring-form",
      quarantine_monitoring_form: %{
        "date_started" => "11/01/2020",
        "date_ended" => "11/15/2020"
      }
    )
    |> Pages.Profile.assert_here(exposed_person)

    %{
      quarantine_monitoring_starts_on: quarantine_monitoring_starts_on,
      quarantine_monitoring_ends_on: quarantine_monitoring_ends_on
    } = ContactInvestigations.get(contact_investigation.id, user)

    assert ~D[2020-11-01] == quarantine_monitoring_starts_on
    assert ~D[2020-11-15] == quarantine_monitoring_ends_on

    assert_recent_audit_log(contact_investigation, user,
      action: "update-contact-investigation",
      event: "edit-contact-investigation-quarantine-monitoring"
    )
  end

  describe "validations" do
    test "shows the errors for missing dates", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
      |> Pages.submit_live("#contact-investigation-quarantine-monitoring-form",
        quarantine_monitoring_form: %{
          "date_started" => "",
          "date_ended" => ""
        }
      )
      |> Pages.assert_validation_messages(%{
        "quarantine_monitoring_form[date_started]" => "can't be blank",
        "quarantine_monitoring_form[date_ended]" => "can't be blank"
      })
    end

    test "shows the errors for invalid dates", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
      |> Pages.submit_live("#contact-investigation-quarantine-monitoring-form",
        quarantine_monitoring_form: %{
          "date_started" => "08/32/2020",
          "date_ended" => "09/31/2020"
        }
      )
      |> Pages.assert_validation_messages(%{
        "quarantine_monitoring_form[date_started]" => "please enter dates as mm/dd/yyyy",
        "quarantine_monitoring_form[date_ended]" => "please enter dates as mm/dd/yyyy"
      })
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes something", %{conn: conn, contact_investigation: contact_investigation} do
      view =
        Pages.ContactInvestigationQuarantineMonitoring.visit(conn, contact_investigation)
        |> Pages.ContactInvestigationQuarantineMonitoring.change_form(
          quarantine_monitoring_form: %{
            "date_started" => "08/30/2020",
            "date_ended" => "09/31/2020"
          }
        )
        |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")

      assert %{"quarantine_monitoring_form[date_started]" => "08/30/2020"} = Pages.form_state(view)
    end
  end
end
