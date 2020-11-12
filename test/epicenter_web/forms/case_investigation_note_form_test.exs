defmodule EpicenterWeb.Forms.CaseInvestigationNoteFormTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Test
  alias Epicenter.Cases
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.preload_demographics()
    [person: person, user: user]
  end

  defp build_case_investigation(person, user, tid, reported_on, attrs \\ %{}) do
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

  test "can see existing notes", %{person: person, user: user, conn: conn} do
    case_investigation = build_case_investigation(person, user, "case_investigation", ~D[2020-08-07])
    Test.Fixtures.case_investigation_note_attrs(case_investigation, user, "note-a", %{text: "Note A"}) |> Cases.create_case_investigation_note!()
    Test.Fixtures.case_investigation_note_attrs(case_investigation, user, "note-b", %{text: "Note B"}) |> Cases.create_case_investigation_note!()

    Pages.Profile.visit(conn, person)
    |> Pages.Profile.assert_case_investigations(%{status: "Pending", status_value: "pending", reported_on: "08/07/2020", number: "001"})
    |> Pages.Profile.assert_notes_showing("001", ["Note A", "Note B"])
  end

  test "can add a new note", %{person: person, user: user, conn: conn} do
    build_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

    Pages.Profile.visit(conn, person)
    |> Pages.Profile.add_note("001", "A new note")
    |> Pages.Profile.assert_notes_showing("001", ["A new note"])
  end

  test "can't add an empty note", %{person: person, user: user, conn: conn} do
    build_case_investigation(person, user, "case_investigation", ~D[2020-08-07])

    Pages.Profile.visit(conn, person)
    |> Pages.Profile.add_note("001", "")
    |> Pages.Profile.assert_case_investigation_note_validation_messages("001", %{"form_field_data_text" => "can't be blank"})
  end
end
