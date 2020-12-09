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

  #  test "prefills with existing data when existing data is available", %{conn: conn, exposure: exposure} do
  #    {:ok, _} =
  #      Cases.update_exposure(
  #        exposure,
  #        {%{interview_started_at: ~N[2020-01-01 23:03:07], interview_proxy_name: "Jackson Publick"}, Test.Fixtures.admin_audit_meta()}
  #      )
  #
  #    Pages.ContactInvestigationStartInterview.visit(conn, exposure)
  #    |> Pages.ContactInvestigationStartInterview.assert_here()
  #    |> Pages.ContactInvestigationStartInterview.assert_proxy_selected("Jackson Publick")
  #    |> Pages.ContactInvestigationStartInterview.assert_time_started("06:03", "PM")
  #    |> Pages.ContactInvestigationStartInterview.assert_date_started("01/01/2020")
  #  end

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
end
