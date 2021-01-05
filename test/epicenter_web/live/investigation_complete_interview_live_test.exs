defmodule EpicenterWeb.InvestigationCompleteInterviewLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(person, user, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, user, "investigation", %{interview_started_at: ~N[2020-01-01 22:03:07]})
      |> Cases.create_case_investigation!()

    [case_investigation: case_investigation, person: person, user: user]
  end

  test "shows investigation form with correct defaults", %{conn: conn, case_investigation: case_investigation} do
    Pages.InvestigationCompleteInterview.visit(conn, case_investigation)
    |> Pages.InvestigationCompleteInterview.assert_here()
    |> Pages.InvestigationCompleteInterview.assert_date_completed(:today)
    |> Pages.InvestigationCompleteInterview.assert_time_completed(:now)
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, case_investigation: case_investigation} do
      Pages.InvestigationCompleteInterview.visit(conn, case_investigation)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes something", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.InvestigationCompleteInterview.visit(conn, case_investigation)
        |> Pages.InvestigationCompleteInterview.change_form(complete_interview_form: %{"date_completed" => "09/06/2020"})
        |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")

      assert %{"complete_interview_form[date_completed]" => "09/06/2020"} = Pages.form_state(view)
    end
  end

  describe "validation" do
    test "invalid times become errors", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.InvestigationCompleteInterview.visit(conn, case_investigation)
        |> Pages.submit_live("#investigation-interview-complete-form",
          complete_interview_form: %{
            "date_completed" => "09/06/2020",
            "time_completed" => "13:45",
            "time_completed_am_pm" => "PM"
          }
        )

      view |> render() |> Pages.assert_validation_messages(%{"complete_interview_form[time_completed]" => "is invalid"})
    end

    test "invalid dates become errors", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.InvestigationCompleteInterview.visit(conn, case_investigation)
        |> Pages.submit_live("#investigation-interview-complete-form",
          complete_interview_form: %{
            "date_completed" => "09/32/2020",
            "time_completed" => "12:45",
            "time_completed_am_pm" => "PM"
          }
        )

      view |> render() |> Pages.assert_validation_messages(%{"complete_interview_form[date_completed]" => "is invalid"})
    end

    test "daylight savings hour that doesn't exist becomes an error", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.InvestigationCompleteInterview.visit(conn, case_investigation)
        |> Pages.submit_live("#investigation-interview-complete-form",
          complete_interview_form: %{
            "date_completed" => "03/08/2020",
            "time_completed" => "02:10",
            "time_completed_am_pm" => "AM"
          }
        )

      view |> render() |> Pages.assert_validation_messages(%{"complete_interview_form[time_completed]" => "is invalid"})
    end

    test "validates presence of all fields", %{conn: conn, case_investigation: case_investigation} do
      view =
        Pages.InvestigationCompleteInterview.visit(conn, case_investigation)
        |> Pages.submit_live("#investigation-interview-complete-form",
          complete_interview_form: %{
            "date_completed" => "",
            "time_completed" => "",
            "time_completed_am_pm" => "AM"
          }
        )

      view
      |> render()
      |> Pages.assert_validation_messages(%{
        "complete_interview_form[date_completed]" => "can't be blank",
        "complete_interview_form[time_completed]" => "can't be blank"
      })
    end
  end

  describe "case investigations" do
    test "prefills with existing data when existing data is available and can be edited", %{conn: conn, case_investigation: case_investigation} do
      {:ok, _} =
        Cases.update_case_investigation(
          case_investigation,
          {%{interview_completed_at: ~N[2020-01-01 23:03:07]}, Test.Fixtures.admin_audit_meta()}
        )

      Pages.InvestigationCompleteInterview.visit(conn, case_investigation)
      |> Pages.InvestigationCompleteInterview.assert_here()
      |> Pages.InvestigationCompleteInterview.assert_time_completed("06:03", "PM")
      |> Pages.InvestigationCompleteInterview.assert_date_completed("01/01/2020")
      |> Pages.submit_and_follow_redirect(conn, "#investigation-interview-complete-form",
        complete_interview_form: %{
          "date_completed" => "09/06/2020",
          "time_completed" => "03:45",
          "time_completed_am_pm" => "PM"
        }
      )

      case_investigation = Cases.get_case_investigation(case_investigation.id)
      assert Timex.to_datetime({{2020, 9, 6}, {19, 45, 0}}, "UTC") == case_investigation.interview_completed_at
    end

    test "saving complete case investigation", %{conn: conn, case_investigation: case_investigation, person: person, user: user} do
      Pages.InvestigationCompleteInterview.visit(conn, case_investigation)
      |> Pages.submit_and_follow_redirect(conn, "#investigation-interview-complete-form",
        complete_interview_form: %{
          "date_completed" => "09/06/2020",
          "time_completed" => "03:45",
          "time_completed_am_pm" => "PM"
        }
      )
      |> Pages.Profile.assert_here(person)
      |> Pages.Profile.assert_case_investigation_has_history(
        "Started interview with Alice Testuser on 01/01/2020 at 05:03pm EST Completed interview on 09/06/2020 at 03:45pm EDT"
      )

      case_investigation = Cases.get_case_investigation(case_investigation.id)
      assert Timex.to_datetime({{2020, 9, 6}, {19, 45, 0}}, "UTC") == case_investigation.interview_completed_at
      assert_recent_audit_log(case_investigation, user, action: "update-case-investigation", event: "complete-case-investigation-interview")
    end
  end

  describe "contact investigations" do
    setup %{case_investigation: case_investigation, user: user} do
      {:ok, contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("contact_investigation", %{exposing_case_id: case_investigation.id}),
         Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      [contact_investigation: contact_investigation, user: user]
    end

    test "saving complete contact investigation", %{conn: conn, contact_investigation: contact_investigation, user: user} do
      refute contact_investigation.interview_completed_at

      Pages.InvestigationCompleteInterview.visit(conn, contact_investigation)
      |> Pages.InvestigationCompleteInterview.assert_header("Complete interview")
      |> Pages.submit_and_follow_redirect(conn, "#investigation-interview-complete-form",
        complete_interview_form: %{
          "date_completed" => "09/06/2020",
          "time_completed" => "03:45",
          "time_completed_am_pm" => "PM"
        }
      )
      |> Pages.Profile.assert_here(contact_investigation.exposed_person)

      contact_investigation = ContactInvestigations.get(contact_investigation.id)
      assert contact_investigation.interview_completed_at
      assert Timex.to_datetime({{2020, 9, 6}, {19, 45, 0}}, "UTC") == contact_investigation.interview_completed_at
      assert_recent_audit_log(contact_investigation, user, action: "update-contact-investigation", event: "complete-contact-investigation-interview")
    end

    test "editing complete contact investigation", %{conn: conn, contact_investigation: contact_investigation, user: user} do
      {:ok, contact_investigation} =
        ContactInvestigations.update(contact_investigation, {
          %{interview_completed_at: ~U[2020-01-02 16:18:42Z]},
          %AuditLog.Meta{
            author_id: user.id,
            reason_action: AuditLog.Revision.update_contact_investigation_action(),
            reason_event: AuditLog.Revision.complete_contact_investigation_interview_event()
          }
        })

      Pages.InvestigationCompleteInterview.visit(conn, contact_investigation)
      |> Pages.InvestigationCompleteInterview.assert_header("Edit interview")
      |> Pages.InvestigationCompleteInterview.assert_time_completed("11:18", "AM")
      |> Pages.InvestigationCompleteInterview.assert_date_completed("01/02/2020")
    end
  end
end
