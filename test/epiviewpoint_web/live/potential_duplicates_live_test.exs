defmodule EpiViewpointWeb.PotentialDuplicatesLiveTest do
  use EpiViewpointWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Merge
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

  setup :register_and_log_in_user
  @admin Test.Fixtures.admin()

  setup %{user: user} do
    person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Test.Fixtures.add_demographic_attrs(%{external_id: "987650"})
      |> Cases.create_person!()

    Test.Fixtures.phone_attrs(user, person, "phone-1", number: "111-111-1000") |> Cases.create_phone!()
    Test.Fixtures.phone_attrs(user, person, "phone-2", number: "111-111-1111") |> Cases.create_phone!()

    Test.Fixtures.demographic_attrs(user, person, "demographic-1", dob: ~D[2001-05-01]) |> Cases.create_demographic()
    Test.Fixtures.demographic_attrs(user, person, "demographic-2", dob: ~D[1999-05-01]) |> Cases.create_demographic()
    Test.Fixtures.demographic_attrs(user, person, "demographic-3", dob: nil) |> Cases.create_demographic()

    Test.Fixtures.address_attrs(user, person, "address-1", 5555) |> Cases.create_address!()
    Test.Fixtures.address_attrs(user, person, "address-2", 4444) |> Cases.create_address!()

    [person: person, user: user]
  end

  defp create_person(user, tid, attrs) do
    Test.Fixtures.person_attrs(user, tid, %{}) |> Test.Fixtures.add_demographic_attrs(attrs) |> Cases.create_person!()
  end

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}/potential-duplicates")

    assert_has_role(disconnected_html, "potential-duplicates-page")
    assert_has_role(page_live, "potential-duplicates-page")
  end

  test "enables and disables the merge button when people are selected / deselected", %{conn: conn, user: user} do
    alice = create_person(user, "alice", %{first_name: "Alice", last_name: "Testuser", dob: ~D[1900-01-01]})
    duplicate = create_person(user, "alice", %{first_name: "Alice", last_name: "Testuser", dob: ~D[1900-01-01]})

    Pages.PotentialDuplicates.visit(conn, alice)
    |> Pages.PotentialDuplicates.assert_merge_button_disabled()
    |> Pages.PotentialDuplicates.set_selected_people([duplicate])
    |> Pages.PotentialDuplicates.assert_merge_button_enabled()
    |> Pages.PotentialDuplicates.set_selected_people([])
    |> Pages.PotentialDuplicates.assert_merge_button_disabled()
  end

  test "shows all relevant information about a person", %{conn: conn, person: person} do
    Pages.PotentialDuplicates.visit(conn, person)
    |> Pages.PotentialDuplicates.assert_here(person)
    |> Pages.PotentialDuplicates.assert_table_contents(
      [
        ["Name", "Date of Birth", "Phone", "Address"],
        [
          "Alice Testuser ID: 987650",
          "05/01/1999 01/01/2000 05/01/2001",
          "(111) 111-1000 (111) 111-1111",
          "4444 Test St, City, OH 00000 5555 Test St, City, OH 00000"
        ]
      ],
      columns: ["Name", "Date of Birth", "Phone", "Address"]
    )
  end

  test "shows all the duplicates of the person", %{conn: conn, user: user} do
    david = create_person(user, "david", %{first_name: "David", last_name: "Testuser", dob: ~D[1900-01-01]})
    create_person(user, "cindy", %{first_name: "Cindy", last_name: "Testuser", dob: ~D[1900-01-01]})
    create_person(user, "billy", %{first_name: "Billy", last_name: "Testuser", dob: ~D[1900-01-01]})

    Pages.PotentialDuplicates.visit(conn, david)
    |> Pages.PotentialDuplicates.assert_here(david)
    |> Pages.PotentialDuplicates.assert_table_contents([["david"], ["billy"], ["cindy"]], tids: true, headers: false, columns: [])
  end

  test "records an audit log entry for the person and their duplicates", %{conn: conn, user: user} do
    alice = create_person(user, "alice", %{first_name: "Alice", last_name: "Testuser", dob: ~D[1900-01-01]})
    billy = create_person(user, "billy", %{first_name: "Billy", last_name: "Testuser", dob: ~D[1900-01-01]})
    cindy = create_person(user, "cindy", %{first_name: "Cindy", last_name: "Testuser", dob: ~D[1900-01-01]})

    AuditLogAssertions.expect_phi_view_logs(8)
    Pages.PotentialDuplicates.visit(conn, alice)
    AuditLogAssertions.verify_phi_view_logged(user, [alice, billy, cindy])
  end

  test "shows potential duplicates who were merged, but then unarchived", %{conn: conn, user: user, person: person} do
    david = create_person(user, "david", %{first_name: "David", last_name: "Testuser", dob: ~D[1900-01-01]})
    create_person(user, "cindy", %{first_name: "Cindy", last_name: "Testuser", dob: ~D[1900-01-01]})
    billy = create_person(user, "billy", %{first_name: "Billy", last_name: "Testuser", dob: ~D[1900-01-01]})

    Merge.merge([billy.id], into: person.id, merge_conflict_resolutions: %{}, current_user: @admin)
    Cases.unarchive_person(billy.id, @admin, Test.Fixtures.admin_audit_meta())

    Pages.PotentialDuplicates.visit(conn, david)
    |> Pages.PotentialDuplicates.assert_here(david)
    |> Pages.PotentialDuplicates.assert_table_contents(
      [["david"], ["billy"], ["cindy"]],
      tids: true,
      headers: false,
      columns: []
    )
  end
end
