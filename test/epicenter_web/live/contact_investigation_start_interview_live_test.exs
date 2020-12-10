defmodule EpicenterWeb.ContactInvestigationStartInterviewLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
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

    {:ok, exposure} =
      {Test.Fixtures.case_investigation_exposure_attrs(case_investigation, "exposure"), Test.Fixtures.admin_audit_meta()}
      |> Cases.create_exposure()

    [exposure: exposure]
  end

  test "saving a start interview contact investigation", %{conn: conn, exposure: exposure} do
    Pages.ContactInvestigationStartInterview.visit(conn, exposure)
    |> Pages.ContactInvestigationStartInterview.assert_here()
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
           } = Cases.get_exposure(exposure.id)
  end

  test "prefills with existing data when existing data is available, and can edit existing data", %{conn: conn, exposure: exposure} do
    {:ok, _} =
      Cases.update_exposure(
        exposure,
        {%{interview_started_at: ~N[2020-01-01 23:03:07], interview_proxy_name: "Jackson Publick"}, Test.Fixtures.admin_audit_meta()}
      )

    Pages.ContactInvestigationStartInterview.visit(conn, exposure)
    |> Pages.ContactInvestigationStartInterview.assert_here()
    |> Epicenter.Extra.tap(fn view ->
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
           } = Cases.get_exposure(exposure.id)
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, exposure: exposure} do
      assert Pages.ContactInvestigationStartInterview.visit(conn, exposure)
             |> Pages.navigation_confirmation_prompt()
             |> Euclid.Exists.blank?()
    end

    test "when the user changes something", %{conn: conn, exposure: exposure} do
      assert Pages.ContactInvestigationStartInterview.visit(conn, exposure)
             |> Pages.ContactInvestigationStartInterview.change_form(start_interview_form: %{"date_started" => "09/06/2020"})
             |> Pages.navigation_confirmation_prompt() == "Your updates have not been saved. Discard updates?"
    end
  end

  test "the back button is there, and can take you back", %{conn: conn, exposure: exposure} do
    Pages.ContactInvestigationStartInterview.visit(conn, exposure)
    |> Pages.ContactInvestigationStartInterview.go_back()
    |> assert_redirects_to("/people/#{exposure.exposed_person_id}")
  end
end
