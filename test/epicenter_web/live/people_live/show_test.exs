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
    Test.Fixtures.email_attrs(person, "alice-1") |> Cases.create_email!()
    Test.Fixtures.email_attrs(person, "alice-2") |> Cases.create_email!()
    Test.Fixtures.phone_attrs(person, "phone-1", number: 1_111_111_000) |> Cases.create_phone!()
    Test.Fixtures.phone_attrs(person, "phone-1", number: 1_111_111_001) |> Cases.create_phone!()

    [person: person]
  end

  describe "show page" do
    test "disconnected and connected render", %{conn: conn, person: person} do
      {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}")

      assert_has_role(disconnected_html, "person-page")
      assert_has_role(page_live, "person-page")
    end

    test "showing person identifying information", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "full-name", "Alice Testuser")
      assert_role_text(page_live, "email-address", "alice-1@example.com, alice-2@example.com")
      assert_role_text(page_live, "phone-number", "111-111-1000, 111-111-1001")
    end

    test("email_address", %{person: person}, do: person |> Show.email_address() |> assert_eq("alice-1@example.com, alice-2@example.com"))

    test("phone_number", %{person: person}, do: person |> Show.phone_number() |> assert_eq("111-111-1000, 111-111-1001"))
  end
end
