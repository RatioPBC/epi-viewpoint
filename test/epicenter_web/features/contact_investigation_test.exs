defmodule EpicenterWeb.Features.ContactInvestigationTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  test "user can edit the details of a case investigation", %{conn: conn, user: user} do
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

    exposed_person = Cases.get_person(exposure.exposed_person_id)

    conn
    |> Pages.Profile.visit(exposed_person)
    |> Pages.Profile.assert_here(exposed_person)
    |> Pages.Profile.click_discontinue_contact_investigation(exposure.tid)
    |> Pages.follow_live_view_redirect(conn)
    |> Pages.ContactInvestigationDiscontinue.assert_here(exposure)
    |> Pages.submit_and_follow_redirect(conn, "#contact-investigation-discontinue-form",
      exposure: %{"interview_discontinue_reason" => "Unable to reach"}
    )
    |> Pages.Profile.assert_here(exposure.exposed_person)
  end
end
