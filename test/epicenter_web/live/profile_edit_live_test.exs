defmodule EpicenterWeb.ProfileEditLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.ProfileEditLive

  describe "render" do
    setup do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      [person: person, user: user]
    end

    test "disconnected and connected render", %{conn: conn, person: %Cases.Person{id: id}} do
      {:ok, view, disconnected_html} = live(conn, "/people/#{id}/edit")

      assert_has_role(disconnected_html, "profile-edit-page")
      assert_has_role(view, "profile-edit-page")
      assert_role_attribute_value(view, "dob", "01/01/2000")
    end

    test "validates changes when the form is changed", %{conn: conn, person: %Cases.Person{id: id}} do
      {:ok, view, _} = live(conn, "/people/#{id}/edit")

      render_change(view, "form-change", %{"person" => %{"dob" => "01/01/197"}})
      |> assert_validation_messages(%{"person_dob" => "please enter dates as mm/dd/yyyy"})

      render_change(view, "form-change", %{"person" => %{"dob" => "01/01/1977", "emails" => %{"0" => %{"address" => ""}}}})
      |> assert_validation_messages(%{"person_emails_0_address" => "can't be blank"})
    end

    test "editing person identifying information works, saves an audit trail, and redirects to the profile page", %{conn: conn, person: person} do
      {:ok, view, _html} = live(conn, "/people/#{person.id}/edit")

      {:ok, redirected_view, _} =
        view
        |> form("#profile-form", person: %{first_name: "Aaron", last_name: "Testuser2", dob: "01/01/2020", preferred_language: "French"})
        |> render_submit()
        |> follow_redirect(conn)

      assert_role_text(redirected_view, "full-name", "Aaron Testuser2")
      assert_role_text(redirected_view, "date-of-birth", "01/01/2020")
      assert_role_text(redirected_view, "preferred-language", "French")
    end

    test "adding email address to a person", %{conn: conn, person: person} do
      {:ok, view, _html} = live(conn, "/people/#{person.id}/edit")

      view |> render_click("add-email")

      {:ok, redirected_view, _} =
        view
        |> form("#profile-form", person: %{"emails" => %{"0" => %{"address" => "alice@example.com"}}})
        |> render_submit()
        |> follow_redirect(conn)

      assert_role_text(redirected_view, "email-address", "alice@example.com")
    end

    test "updating existing email address", %{conn: conn, person: person} do
      Test.Fixtures.email_attrs(person, "alice-a") |> Cases.create_email!()
      {:ok, view, _html} = live(conn, "/people/#{person.id}/edit")

      assert_attribute(view, "[data-tid=alice-a]", "value", ["alice-a@example.com"])

      {:ok, redirected_view, _} =
        view
        |> form("#profile-form", person: %{"emails" => %{"0" => %{"address" => "alice-b@example.com"}}})
        |> render_submit()
        |> follow_redirect(conn)

      assert_role_text(redirected_view, "email-address", "alice-b@example.com")
    end

    test "deleting existing email address", %{conn: conn, person: person} do
      email = Test.Fixtures.email_attrs(person, "alice-a") |> Cases.create_email!()
      {:ok, view, _html} = live(conn, "/people/#{person.id}/edit")

      refute view |> render_click("remove-email", %{"remove" => email.id}) =~ "alice-a@example.com"

      {:ok, redirected_view, _} =
        view
        |> form("#profile-form", person: %{"emails" => %{}})
        |> render_submit()
        |> follow_redirect(conn)

      assert_role_text(redirected_view, "email-address", "Unknown")
    end

    test "editing preferred language with other option", %{conn: conn, person: person} do
      {:ok, view, _html} = live(conn, "/people/#{person.id}/edit")

      {:ok, redirected_live, _} =
        view
        |> form("#profile-form",
          person: %{
            first_name: "Aaron",
            last_name: "Testuser2",
            dob: "01/01/2020",
            preferred_language: "Other",
            other_specified_language: "Welsh"
          }
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert_role_text(redirected_live, "full-name", "Aaron Testuser2")
      assert_role_text(redirected_live, "date-of-birth", "01/01/2020")
      assert_role_text(redirected_live, "preferred-language", "Welsh")

      # the custom option appears in the dropdown if you edit it again after saving
      {:ok, view, _html} = live(conn, "/people/#{person.id}/edit")
      assert_selected_dropdown_option(view: view, data_role: "preferred-language", expected: ["Welsh"])
      assert_attribute(view, "[data-role=other-preferred-language]", "data-disabled", ["data-disabled"])
    end
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

  describe "clean_up_language" do
    test "updates parameters with other specified language if present" do
      %{"first_name" => "Aaron", "preferred_language" => "Other", "other_specified_language" => "Piglatin"}
      |> ProfileEditLive.clean_up_languages()
      |> assert_eq(%{"first_name" => "Aaron", "preferred_language" => "Piglatin", "other_specified_language" => "Piglatin"})
    end

    test "noop when preferred_language is not `Other`" do
      %{"first_name" => "Aaron", "preferred_language" => "English"}
      |> ProfileEditLive.clean_up_languages()
      |> assert_eq(%{"first_name" => "Aaron", "preferred_language" => "English"})
    end
  end
end
