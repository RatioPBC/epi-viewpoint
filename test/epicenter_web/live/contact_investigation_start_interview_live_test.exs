defmodule EpicenterWeb.ContactInvestigationStartInterviewLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    sick_person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Cases.create_person!()

    lab_result =
      Test.Fixtures.lab_result_attrs(sick_person, user, "lab_result", ~D[2020-08-07])
      |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(sick_person, lab_result, user, "the contagious person's case investigation")
      |> Cases.create_case_investigation!()

    {:ok, contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs("contact_investigation", %{exposing_case_id: case_investigation.id}),
       Test.Fixtures.admin_audit_meta()}
      |> ContactInvestigations.create()

    [contact_investigation: contact_investigation]
  end

  test "records an audit log entry", %{conn: conn, contact_investigation: contact_investigation, user: user} do
    capture_log(fn -> Pages.ContactInvestigationStartInterview.visit(conn, contact_investigation) end)
    |> AuditLogAssertions.assert_viewed_person(user, contact_investigation.exposed_person)
  end

  test "saving a start interview contact investigation", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationStartInterview.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationStartInterview.assert_here()
    |> Epicenter.Extra.tap(fn view ->
      assert Pages.ContactInvestigationStartInterview.time_started(view) =~ ~r[^\d\d:\d\d((AM)|(PM))$]
      assert Pages.ContactInvestigationStartInterview.date_started(view) =~ ~r[^\d\d\/\d\d/\d\d\d\d$]
      assert Pages.ContactInvestigationStartInterview.form_title(view) == "Start interview"
    end)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-interview-start-form",
      start_interview_form: %{
        "person_interviewed" => "Jason Bourne",
        "date_started" => "09/07/2020",
        "time_started" => "04:45",
        "time_started_am_pm" => "PM"
      }
    )

    assert %{
             interview_status: "started",
             interview_started_at: ~U[2020-09-07 20:45:00Z],
             interview_proxy_name: "Jason Bourne"
           } = ContactInvestigations.get(contact_investigation.id)
  end

  test "prefills with existing data when existing data is available, and can edit existing data", %{
    conn: conn,
    contact_investigation: contact_investigation
  } do
    {:ok, _} =
      ContactInvestigations.update(
        contact_investigation,
        {%{interview_started_at: ~N[2020-01-01 23:03:07], interview_proxy_name: "Jackson Publick"}, Test.Fixtures.admin_audit_meta()}
      )

    Pages.ContactInvestigationStartInterview.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationStartInterview.assert_here()
    |> Epicenter.Extra.tap(fn view ->
      assert Pages.ContactInvestigationStartInterview.form_title(view) == "Edit start interview"
      assert Pages.ContactInvestigationStartInterview.time_started(view) == "06:03PM"
      assert Pages.ContactInvestigationStartInterview.date_started(view) == "01/01/2020"
    end)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-interview-start-form",
      start_interview_form: %{
        "person_interviewed" => "~~self~~",
        "date_started" => "09/07/2020",
        "time_started" => "04:45",
        "time_started_am_pm" => "PM"
      }
    )

    assert %{
             interview_status: "started",
             interview_started_at: ~U[2020-09-07 20:45:00Z],
             interview_proxy_name: nil
           } = ContactInvestigations.get(contact_investigation.id)
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, contact_investigation: contact_investigation} do
      Pages.ContactInvestigationStartInterview.visit(conn, contact_investigation)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes something", %{conn: conn, contact_investigation: contact_investigation} do
      view =
        Pages.ContactInvestigationStartInterview.visit(conn, contact_investigation)
        |> Pages.ContactInvestigationStartInterview.change_form(start_interview_form: %{"date_started" => "09/06/2020"})
        |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")

      assert %{"start_interview_form[date_started]" => "09/06/2020"} = Pages.form_state(view)
    end
  end

  test "the back button is there, and can take you back", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationStartInterview.visit(conn, contact_investigation)
    |> Pages.ContactInvestigationStartInterview.go_back()
    |> assert_redirects_to("/people/#{contact_investigation.exposed_person_id}")
  end

  test "date_started, time_started, and person interviewed are required", %{conn: conn, contact_investigation: contact_investigation} do
    Pages.ContactInvestigationStartInterview.visit(conn, contact_investigation)
    |> Pages.submit_live("#contact-investigation-interview-start-form",
      start_interview_form: %{
        "person_interviewed" => "",
        "date_started" => "",
        "time_started" => "",
        "time_started_am_pm" => "PM"
      }
    )
    |> Epicenter.Extra.tap(fn view ->
      assert Pages.validation_messages(view) == %{
               "start_interview_form[person_interviewed]" => "can't be blank",
               "start_interview_form[date_started]" => "can't be blank",
               "start_interview_form[time_started]" => "can't be blank"
             }
    end)
  end
end
