defmodule EpicenterWeb.ProfileEditLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Euclid.Extra.Enum, only: [pluck: 2]
  import Phoenix.LiveViewTest

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias EpicenterWeb.ProfileEditLive

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    [person: person]
  end

  describe "render" do
    test "disconnected and connected render", %{conn: conn, person: %Cases.Person{id: id}} do
      {:ok, view, disconnected_html} = live(conn, "/people/#{id}/edit")

      assert_has_role(disconnected_html, "profile-edit-page")
      assert_has_role(view, "profile-edit-page")
      assert_role_attribute_value(view, "dob", "01/01/2000")
    end

    test "validates changes when the form is saved (not merely changed)", %{conn: conn, person: %Cases.Person{id: id}} do
      {:ok, view, _} = live(conn, "/people/#{id}/edit")

      changes = %{"person" => %{"dob" => "01/01/197", "emails" => %{"0" => %{"address" => ""}}}}

      view |> render_click("add-email")

      render_change(view, "form-change", changes)
      |> assert_validation_messages(%{})

      view
      |> form("#profile-form", changes)
      |> render_submit()
      |> assert_validation_messages(%{"person_dob" => "please enter dates as mm/dd/yyyy"})
    end

    test "dob field retains invalid date after failed validation, rather than resetting to the value from the database", %{conn: conn, person: person} do
      {:ok, view, _html} = live(conn, "/people/#{person.id}/edit")

      assert_attribute(view, "input[data-role=dob]", "value", ["01/01/2000"])

      rendered = view |> form("#profile-form", person: %{"dob" => "Jan 4 1928"}) |> render_submit()

      assert_attribute(view, "input[data-role=dob]", "value", ["Jan 4 1928"])
      assert_validation_messages(rendered, %{"person_dob" => "please enter dates as mm/dd/yyyy"})
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

  describe "email addresses" do
    test "adding email address to a person", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_email_form(%{})
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.submit_and_follow_redirect(conn, %{"emails" => %{"0" => %{"address" => "alice@example.com"}}})
      |> Pages.Profile.assert_email_addresses(["alice@example.com"])

      Cases.get_person(person.id) |> Cases.preload_emails() |> Map.get(:emails) |> pluck(:address) |> assert_eq(["alice@example.com"])
    end

    test "updating existing email address", %{conn: conn, person: person} do
      Test.Fixtures.email_attrs(person, "alice-a") |> Cases.create_email!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_email_form(%{"person[emails][0][address]" => "alice-a@example.com"})
      |> Pages.ProfileEdit.submit_and_follow_redirect(conn, %{"emails" => %{"0" => %{"address" => "alice-b@example.com"}}})
      |> Pages.Profile.assert_email_addresses(["alice-b@example.com"])
    end

    test "deleting existing email address", %{conn: conn, person: person} do
      Test.Fixtures.email_attrs(person, "alice-a") |> Cases.create_email!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_email_form(%{"person[emails][0][address]" => "alice-a@example.com"})
      |> Pages.ProfileEdit.click_remove_email_button(index: "0")
      |> Pages.ProfileEdit.assert_email_form(%{})
      |> Pages.ProfileEdit.submit_and_follow_redirect(conn, %{"emails" => %{}})
      |> Pages.Profile.assert_email_addresses(["Unknown"])

      Cases.get_person(person.id) |> Cases.preload_emails() |> Map.get(:emails) |> assert_eq([])
    end

    test "blank email addresses are ignored (rather than being validation errors)", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.submit_and_follow_redirect(conn, %{
        "emails" => %{"0" => %{"address" => "alice-0@example.com"}, "1" => %{"address" => ""}}
      })
      |> Pages.Profile.assert_email_addresses(["alice-0@example.com"])
    end

    test "clicking add email address button does not reset state of form", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.change_form(%{"emails" => %{"0" => %{"address" => "alice-0@example.com"}}})
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.assert_email_form(%{"person[emails][0][address]" => "alice-0@example.com", "person[emails][1][address]" => ""})
      |> Pages.ProfileEdit.assert_validation_messages(%{})
    end

    test "email label hides when no emails are present", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.refute_email_label_present()
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.assert_email_label_present()
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.click_remove_email_button(index: "1")
      |> Pages.ProfileEdit.assert_email_label_present()
      |> Pages.ProfileEdit.click_remove_email_button(index: "0")
      |> Pages.ProfileEdit.refute_email_label_present()
      |> Pages.ProfileEdit.assert_email_form(%{})
    end
  end

  describe "phone numbers" do
    test "adding phone number to a person", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_phone_number_form(%{})
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.ProfileEdit.submit_and_follow_redirect(conn, %{"phones" => %{"0" => %{"number" => "1111111000"}}})
      |> Pages.Profile.assert_phone_numbers(["111-111-1000"])

      Cases.get_person(person.id) |> Cases.preload_phones() |> Map.get(:phones) |> pluck(:number) |> assert_eq([1_111_111_000])
    end

    test "updating existing phone numbers", %{conn: conn, person: person} do
      Test.Fixtures.phone_attrs(person, "phone-1", number: 1_111_111_000) |> Cases.create_phone!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_phone_number_form(%{"person[phones][0][number]" => "1111111000"})
      |> Pages.ProfileEdit.submit_and_follow_redirect(conn, %{"phones" => %{"0" => %{"number" => "1111111001"}}})
      |> Pages.Profile.assert_phone_numbers(["111-111-1001"])
    end

    test "deleting existing phone numbers", %{conn: conn, person: person} do
      Test.Fixtures.phone_attrs(person, "phone-1", number: 1_111_111_000) |> Cases.create_phone!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_phone_number_form(%{"person[phones][0][number]" => "1111111000"})
      |> Pages.ProfileEdit.click_remove_phone_button(index: "0")
      |> Pages.ProfileEdit.assert_phone_number_form(%{})
      |> Pages.ProfileEdit.submit_and_follow_redirect(conn, %{"phones" => %{}})
      |> Pages.Profile.assert_phone_numbers(["Unknown"])

      Cases.get_person(person.id) |> Cases.preload_phones() |> Map.get(:phones) |> assert_eq([])
    end

    test "blank phone numbers are ignored (rather than being validation errors)", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.ProfileEdit.submit_and_follow_redirect(conn, %{
        "phones" => %{"0" => %{"number" => "1111111001"}, "1" => %{"number" => ""}}
      })
      |> Pages.Profile.assert_phone_numbers(["111-111-1001"])
    end

    test "clicking phone number button does not reset state of form", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.ProfileEdit.change_form(%{"phones" => %{"0" => %{"number" => "1111111001"}}})
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.ProfileEdit.assert_phone_number_form(%{"person[phones][0][number]" => "1111111001", "person[phones][1][number]" => ""})
      |> Pages.ProfileEdit.assert_validation_messages(%{})
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

  describe "remove_blank_email_addresses" do
    test "removes empty email addresses from the params" do
      %{"first_name" => "Alice", "emails" => %{"0" => %{"address" => "alice-0@example.com"}, "1" => %{"address" => ""}}}
      |> ProfileEditLive.remove_blank_email_addresses()
      |> assert_eq(%{"first_name" => "Alice", "emails" => %{"0" => %{"address" => "alice-0@example.com"}}}, :simple)
    end

    test "removes blank email addresses from the params" do
      %{"first_name" => "Alice", "emails" => %{"0" => %{"address" => "  "}, "1" => %{"address" => nil}}}
      |> ProfileEditLive.remove_blank_email_addresses()
      |> assert_eq(%{"first_name" => "Alice", "emails" => %{}}, :simple)
    end

    test "does nothing when there are no email addresses" do
      %{"first_name" => "Alice"}
      |> ProfileEditLive.remove_blank_email_addresses()
      |> assert_eq(%{"first_name" => "Alice"})
    end
  end
end
