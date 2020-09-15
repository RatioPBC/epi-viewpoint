defmodule EpicenterWeb.PeopleLive.ShowTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.PeopleLive.Show

  setup do
    user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    [person: person]
  end

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}")

    assert_has_role(disconnected_html, "person-page")
    assert_has_role(page_live, "person-page")
  end

  describe "when the person has no identifying information" do
    test "showing person identifying information", %{conn: conn, person: person} do
      {:ok, _} = Cases.update_person(person, preferred_language: nil)
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "preferred-language", "Unknown")
      assert_role_text(page_live, "phone-number", "Unknown")
      assert_role_text(page_live, "email-address", "Unknown")
      assert_role_text(page_live, "address", "Unknown")
    end

    test("email_addresses", %{person: person}, do: person |> Show.email_addresses() |> assert_eq([]))

    test("phone_numbers", %{person: person}, do: person |> Show.phone_numbers() |> assert_eq([]))
  end

  describe "when the person has identifying information" do
    setup %{person: person} do
      Test.Fixtures.email_attrs(person, "alice-a") |> Cases.create_email!()
      Test.Fixtures.email_attrs(person, "alice-preferred", is_preferred: true) |> Cases.create_email!()
      Test.Fixtures.phone_attrs(person, "phone-1", number: 1_111_111_000) |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(person, "phone-2", number: 1_111_111_001, is_preferred: true) |> Cases.create_phone!()
      Test.Fixtures.address_attrs(person, "alice-address", type: "home") |> Cases.create_address!()
      Test.Fixtures.address_attrs(person, "alice-address-preferred", type: nil, is_preferred: true) |> Cases.create_address!()
      :ok
    end

    test "showing person identifying information", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "full-name", "Alice Testuser")
      assert_role_text(page_live, "date-of-birth", "01/01/2000")
      assert_role_text(page_live, "preferred-language", "English")
      assert_role_text(page_live, "phone-number", "111-111-1001 111-111-1000")
      assert_role_text(page_live, "email-address", "alice-preferred@example.com alice-a@example.com")
      assert_role_text(page_live, "address", "123 alice-address-preferred st, TestAddress 123 alice-address st, TestAddress home")
    end

    test "email_addresses", %{person: person} do
      person |> Show.email_addresses() |> assert_eq(["alice-preferred@example.com", "alice-a@example.com"])
    end

    test "phone_numbers", %{person: person} do
      person |> Show.phone_numbers() |> assert_eq(["111-111-1001", "111-111-1000"])
    end
  end

  describe "when the person has no test results" do
    test "", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      page_live
      |> assert_role_text("lab-results", "Lab Results No lab results")
    end
  end

  defp test_result_table_contents(page_live),
       do: page_live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(role: "lab-result-table")

  describe "when the person has test results" do
    setup %{person: person} do
      Test.Fixtures.lab_result_attrs(person, "lab1", ~D[2020-04-10], %{
        result: "positive",
        request_facility_name: "Big Big Hospital",
        analyzed_on: ~D[2020-04-11],
        reported_on: ~D[2020-04-12],
        test_type: "PCR"
      })
      |> Cases.create_lab_result!()

      Test.Fixtures.lab_result_attrs(person, "lab1", ~D[2020-04-12], %{
        result: "positive",
        request_facility_name: "Big Big Hospital",
        analyzed_on: ~D[2020-04-13],
        reported_on: ~D[2020-04-14],
        test_type: "PCR"
      }) |> Cases.create_lab_result!()
      :ok
    end

    test "", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      page_live
      |> test_result_table_contents()
      |> assert_eq([
        ["Collection", "Result", "Ordering Facility", "Analysis", "Reported", "Type"],
        ["04/10/2020", "positive", "Big Big Hospital", "04/11/2020", "04/12/2020", "PCR"],
        ["04/12/2020", "positive", "Big Big Hospital", "04/13/2020", "04/14/2020", "PCR"]
      ])
    end
  end
end
