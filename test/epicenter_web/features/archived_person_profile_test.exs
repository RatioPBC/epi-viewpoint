defmodule EpicenterWeb.Features.ArchivedPersonProfileTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Test.Fixtures.add_demographic_attrs(%{external_id: "987650"})
      |> Cases.create_person!()
      |> Cases.preload_case_investigations()

    [person: person, user: user]
  end

  test "no buttons on profile of archived person with pending case investigation", %{conn: conn, user: user, person: person} do
    create_case_investigation(person, user, "pending-case-investigation", ~D[2021-01-28], %{})

    Cases.archive_person(person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person with started case investigation interview", %{conn: conn, user: user, person: person} do
    create_case_investigation(person, user, "started-case-investigation", nil, %{
      interview_started_at: NaiveDateTime.utc_now(),
      clinical_status: "symptomatic"
    })

    Cases.archive_person(person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person with discontinued case investigation interview", %{conn: conn, user: user, person: person} do
    create_case_investigation(person, user, "case_investigation", nil, %{
      interview_started_at: ~U[2020-10-31 22:03:07Z],
      interview_discontinued_at: ~U[2020-10-31 23:03:07Z],
      interview_discontinue_reason: "Unable to reach"
    })

    Cases.archive_person(person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person with completed case investigation interview", %{conn: conn, user: user, person: person} do
    create_case_investigation(person, user, "completed-case-investigation", nil, %{
      interview_completed_at: ~U[2020-10-31 23:03:07Z],
      interview_started_at: ~U[2020-10-31 22:03:07Z]
    })

    Cases.archive_person(person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person with started case investigation isolation monitoring", %{conn: conn, user: user, person: person} do
    create_case_investigation(person, user, "case_investigation", nil, %{
      interview_completed_at: ~U[2020-10-05 19:57:00Z],
      interview_started_at: ~U[2020-10-05 18:57:00Z],
      isolation_monitoring_starts_on: ~D[2020-11-05],
      isolation_monitoring_ends_on: ~D[2020-11-15]
    })

    Cases.archive_person(person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person with completed case investigation isolation monitoring", %{conn: conn, user: user, person: person} do
    create_case_investigation(person, user, "case_investigation", nil, %{
      interview_completed_at: ~U[2020-10-05 19:57:00Z],
      interview_started_at: ~U[2020-10-05 18:57:00Z],
      isolation_concluded_at: ~U[2020-11-15 19:57:00Z],
      isolation_conclusion_reason: "successfully_completed",
      isolation_monitoring_ends_on: ~D[2020-11-15],
      isolation_monitoring_starts_on: ~D[2020-11-05]
    })

    Cases.archive_person(person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person who is the subject of a pending contact investigation", %{conn: conn, user: user, person: person} do
    contact_investigation =
      create_contact_investigation(user, person, %{}, %{}, %{
        tid: "contact_investigation"
      })

    Cases.archive_person(contact_investigation.exposed_person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, contact_investigation.exposed_person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person who is the subject of an ongoing contact investigation", %{conn: conn, user: user, person: person} do
    contact_investigation =
      create_contact_investigation(user, person, %{}, %{}, %{
        tid: "contact_investigation",
        interview_started_at: ~U[2020-10-05 18:57:00Z]
      })

    Cases.archive_person(contact_investigation.exposed_person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, contact_investigation.exposed_person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person who is the subject contact investigation with a completed interview",
       %{conn: conn, user: user, person: person} do
    contact_investigation =
      create_contact_investigation(user, person, %{}, %{}, %{
        tid: "contact_investigation",
        interview_started_at: ~U[2020-10-05 18:57:00Z],
        interview_completed_at: ~U[2020-10-05 19:57:00Z]
      })

    Cases.archive_person(contact_investigation.exposed_person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, contact_investigation.exposed_person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person who is the quarantining subject of a contact investigation",
       %{conn: conn, user: user, person: person} do
    contact_investigation =
      create_contact_investigation(user, person, %{}, %{}, %{
        tid: "contact_investigation",
        interview_started_at: ~U[2020-10-05 18:57:00Z],
        interview_completed_at: ~U[2020-10-05 19:57:00Z],
        quarantine_monitoring_starts_on: ~D[2020-11-05],
        quarantine_monitoring_ends_on: ~D[2020-11-15]
      })

    Cases.archive_person(contact_investigation.exposed_person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, contact_investigation.exposed_person)
    |> assert_no_edit_buttons_or_links()
  end

  test "no buttons on profile of archived person who is subject of a contact investigation who has completed their quarantine",
       %{conn: conn, user: user, person: person} do
    contact_investigation =
      create_contact_investigation(user, person, %{}, %{}, %{
        tid: "contact_investigation",
        interview_started_at: ~U[2020-10-05 18:57:00Z],
        interview_completed_at: ~U[2020-10-05 19:57:00Z],
        quarantine_monitoring_starts_on: ~D[2020-11-05],
        quarantine_monitoring_ends_on: ~D[2020-11-15],
        quarantine_concluded_at: ~U[2020-11-15 19:57:00Z],
        quarantine_conclusion_reason: "successfully_completed_quarantine"
      })

    Cases.archive_person(contact_investigation.exposed_person.id, user, Test.Fixtures.admin_audit_meta())

    Pages.Profile.visit(conn, contact_investigation.exposed_person)
    |> assert_no_edit_buttons_or_links()
  end

  defp assert_no_edit_buttons_or_links(view) do
    all_buttons =
      view
      |> Pages.parse()
      |> Test.Html.find("button")
      |> ignore_unarchive_button()
      |> ignore_current_user_settings_dropdown()

    assert [] == all_buttons

    all_links =
      view
      |> Pages.parse()
      |> Test.Html.find("a")
      |> ignore_logo_link()
      |> ignore_logout_link()
      |> ignore_case_investigations_link()
      |> ignore_contacts_link()
      |> ignore_user_settings_link()
      |> ignore_case_investigations_scroll_anchor_link
      |> ignore_contact_investigations_scroll_anchor_link
      |> ignore_visit_exposing_case_link()

    assert [] == all_links
  end

  defp ignore_current_user_settings_dropdown(list_of_buttons) do
    Enum.filter(list_of_buttons, fn button ->
      Test.Html.attr(button, "data-role") != ["current-user-name"]
    end)
  end

  # the unarchive button is the only edit-person button that is allowed on an archived person
  defp ignore_unarchive_button(list_of_buttons) do
    Enum.filter(list_of_buttons, fn button ->
      Test.Html.attr(button, "data-role") != ["unarchive"]
    end)
  end

  defp ignore_logo_link(list_of_anchors) do
    Enum.filter(list_of_anchors, fn link ->
      Test.Html.attr(link, "id") != ["logo", "mask0"]
    end)
  end

  defp ignore_logout_link(list_of_anchors) do
    Enum.filter(list_of_anchors, fn link ->
      Test.Html.attr(link, "data-to") != ["/users/log-out"]
    end)
  end

  defp ignore_case_investigations_link(list_of_anchors) do
    Enum.filter(list_of_anchors, fn link ->
      Test.Html.attr(link, "href") != ["/people"]
    end)
  end

  defp ignore_contacts_link(list_of_anchors) do
    Enum.filter(list_of_anchors, fn link ->
      Test.Html.attr(link, "href") != ["/contacts"]
    end)
  end

  defp ignore_user_settings_link(list_of_anchors) do
    Enum.filter(list_of_anchors, fn link ->
      Test.Html.attr(link, "href") != ["/users/settings"]
    end)
  end

  defp ignore_case_investigations_scroll_anchor_link(list_of_anchors) do
    Enum.filter(list_of_anchors, fn link ->
      Test.Html.attr(link, "id") != ["case-investigations"]
    end)
  end

  defp ignore_contact_investigations_scroll_anchor_link(list_of_anchors) do
    Enum.filter(list_of_anchors, fn link ->
      Test.Html.attr(link, "id") != ["contact-investigations"]
    end)
  end

  defp ignore_visit_exposing_case_link(list_of_anchors) do
    Enum.filter(list_of_anchors, fn link ->
      Test.Html.attr(link, "data-role") != ["visit-exposing-case-link"]
    end)
  end

  #

  defp create_case_investigation(person, user, tid, reported_on, attrs) do
    lab_result =
      Test.Fixtures.lab_result_attrs(person, user, "lab_result_#{tid}", reported_on, %{
        result: "positive",
        request_facility_name: "Big Big Hospital",
        reported_on: reported_on,
        test_type: "PCR"
      })
      |> Cases.create_lab_result!()

    Test.Fixtures.case_investigation_attrs(
      person,
      lab_result,
      user,
      tid,
      %{name: "001"}
      |> Map.merge(attrs)
    )
    |> Cases.create_case_investigation!()
  end

  defp create_contact_investigation(user, sick_person, lab_result_attrs, case_investigation_attrs, contact_investigation_attrs) do
    lab_result =
      Test.Fixtures.lab_result_attrs(sick_person, user, "lab_result", ~D[2020-08-07], lab_result_attrs)
      |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(sick_person, lab_result, user, "the contagious person's case investigation", case_investigation_attrs)
      |> Cases.create_case_investigation!()

    {:ok, contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs(
         "contact_investigation",
         Map.put(contact_investigation_attrs, :exposing_case_id, case_investigation.id)
       ), Test.Fixtures.admin_audit_meta()}
      |> ContactInvestigations.create()

    contact_investigation
  end
end
