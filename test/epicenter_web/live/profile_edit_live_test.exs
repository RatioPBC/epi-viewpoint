defmodule EpicenterWeb.ProfileEditLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.ProfileEditLive

  test "disconnected and connected render", %{conn: conn} do
    user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
    %Cases.Person{id: id} = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

    {:ok, page_live, disconnected_html} = live(conn, "/people/#{id}/edit")

    assert_has_role(disconnected_html, "profile-edit-page")
    assert_has_role(page_live, "profile-edit-page")
    assert_role_attribute_value(page_live, "dob", "01/01/2000")
  end

  test "validating  changes", %{conn: conn} do
    user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
    %Cases.Person{id: id} = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

    {:ok, page_live, _} = live(conn, "/people/#{id}/edit")

    assert render_change(page_live, "validate", %{"person" => %{"dob" => "01/01/197"}}) =~ "please enter dates as mm/dd/yyyy"
  end

  test "editing person identifying information works, saves an audit trail, and redirects to the profile page", %{conn: conn} do
    user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

    {:ok, page_live, _html} = live(conn, "/people/#{person.id}/edit")

    {:ok, redirected_view, _} =
      page_live
      |> form("#profile-form", person: %{first_name: "Aaron", last_name: "Testuser2", dob: "01/01/2020", preferred_language: "French"})
      |> render_submit()
      |> follow_redirect(conn)

    assert_role_text(redirected_view, "full-name", "Aaron Testuser2")
    assert_role_text(redirected_view, "date-of-birth", "01/01/2020")
    assert_role_text(redirected_view, "preferred-language", "French")
    assert_versioned(person, expected_count: 2)
  end

  describe "preferred_languages" do
    test "returns a list of preferred-language tuples" do
      "Piglatin"
      |> ProfileEditLive.preferred_languages()
      |> Enum.each(fn language ->
        assert {lang, lang} = language
      end)
    end

    test "includes the passed-in current language" do
      assert {"Piglatin", "Piglatin"} in ProfileEditLive.preferred_languages("Piglatin")
    end

    test "does not include blank preferred language" do
      refute {"", ""} in ProfileEditLive.preferred_languages("")
      refute {nil, nil} in ProfileEditLive.preferred_languages(nil)
    end

    test "does not duplicate existing languages" do
      ProfileEditLive.preferred_languages("English")
      |> Enum.count(fn {lang, lang} -> lang == "English" end)
      |> assert_eq(1)
    end
  end
end
