defmodule EpicenterWeb.PotentialDuplicatesLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

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

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}/potential-duplicates")

    assert_has_role(disconnected_html, "potential-duplicates-page")
    assert_has_role(page_live, "potential-duplicates-page")
  end

  test "showing the page", %{conn: conn, person: person} do
    Pages.PotentialDuplicates.visit(conn, person)
    |> Pages.PotentialDuplicates.assert_here(person)
    |> Pages.PotentialDuplicates.assert_table_contents(
      [
        ["Name", "Date of Birth", "Phone", "Address"],
        [
          "Alice Testuser",
          "05/01/1999 01/01/2000 05/01/2001",
          "(111) 111-1000 (111) 111-1111",
          "4444 Test St, City, OH 00000 5555 Test St, City, OH 00000"
        ]
      ],
      columns: ["Name", "Date of Birth", "Phone", "Address"]
    )
  end
end
