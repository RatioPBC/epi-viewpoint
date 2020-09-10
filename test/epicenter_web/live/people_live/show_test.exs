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
      assert_role_text(page_live, "address-type", "")
    end

    test("address", %{person: person}, do: person |> Show.address(:full_address) |> assert_eq(nil))

    test("email_address", %{person: person}, do: person |> Show.email_address() |> assert_eq(nil))

    test("phone_number", %{person: person}, do: person |> Show.phone_number() |> assert_eq(nil))
  end

  describe "when the person has identifying information" do
    setup %{person: person} do
      Test.Fixtures.email_attrs(person, "alice-1") |> Cases.create_email!()
      Test.Fixtures.email_attrs(person, "alice-2") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(person, "phone-1", number: 1_111_111_000) |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(person, "phone-1", number: 1_111_111_001) |> Cases.create_phone!()
      Test.Fixtures.address_attrs(person, "alice-address-1", type: "home") |> Cases.create_address!()
      Test.Fixtures.address_attrs(person, "alice-address-2") |> Cases.create_address!()
      :ok
    end

    test "showing person identifying information", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "full-name", "Alice Testuser")
      assert_role_text(page_live, "preferred-language", "English")
      assert_role_text(page_live, "phone-number", "111-111-1000, 111-111-1001")
      assert_role_text(page_live, "email-address", "alice-1@example.com, alice-2@example.com")
      assert_role_text(page_live, "address", "123 alice-address-1 st, TestAddress")
      assert_role_text(page_live, "address-type", "home")
    end

    test("address", %{person: person}, do: person |> Show.address(:full_address) |> assert_eq("123 alice-address-1 st, TestAddress"))

    test("email_address", %{person: person}, do: person |> Show.email_address() |> assert_eq("alice-1@example.com, alice-2@example.com"))

    test("phone_number", %{person: person}, do: person |> Show.phone_number() |> assert_eq("111-111-1000, 111-111-1001"))
  end
end
