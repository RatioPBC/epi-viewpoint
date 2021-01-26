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
    [person: person, user: user]
  end

  describe "render" do
    test "disconnected and connected render", %{conn: conn, person: %Cases.Person{id: id}} do
      {:ok, view, disconnected_html} = live(conn, "/people/#{id}/edit")

      assert_has_role(disconnected_html, "profile-edit-page")
      assert_has_role(view, "profile-edit-page")
      assert_role_attribute_value(view, "dob", "01/01/2000")
    end

    test "records an audit log entry", %{conn: conn, person: person, user: user} do
      capture_log(fn -> Pages.ProfileEdit.visit(conn, person) end)
      |> AuditLogAssertions.assert_viewed_person(user, person)
    end

    @tag :skip
    test "validates changes when the form is saved (not merely changed)", %{conn: conn, person: person} do
      view = Pages.ProfileEdit.visit(conn, person)

      changes = %{"form_data" => %{"dob" => "01/01/197", "emails" => %{"0" => %{"address" => ""}}}}

      view |> render_click("add-email")

      render_change(view, "form-change", changes)
      |> Pages.assert_validation_messages(%{})

      view
      |> form("#profile-form", changes)
      |> render_submit()
      |> Pages.assert_validation_messages(%{"form_data[dob]" => "please enter dates as mm/dd/yyyy"})
    end

    test "making a 'form' demographic", %{conn: conn, person: person, user: user} do
      {:ok, person} =
        Cases.update_person(
          person,
          {%{demographics: person.demographics |> Enum.map(fn demo -> %{id: demo.id, source: "import"} end)}, Test.Fixtures.admin_audit_meta()}
        )

      view = Pages.ProfileEdit.visit(conn, person)

      changes = %{"form_data" => %{"dob" => "01/01/1970"}}

      {:ok, redirected_live, _} =
        view
        |> form("#profile-form", changes)
        |> render_submit()
        |> follow_redirect(conn)

      assert_role_text(redirected_live, "date-of-birth", "01/01/1970")

      assert [%{source: "import"}, %{source: "form", first_name: nil, dob: ~D[1970-01-01]}] =
               Cases.get_person(person.id, user) |> Cases.preload_demographics() |> Map.get(:demographics)
    end

    test "modifying the 'form' demographic", %{conn: conn, person: person, user: user} do
      {:ok, person} =
        Cases.update_person(
          person,
          {%{demographics: person.demographics |> Enum.map(fn demo -> %{id: demo.id, source: "form"} end)}, Test.Fixtures.admin_audit_meta()}
        )

      view = Pages.ProfileEdit.visit(conn, person)

      changes = %{"form_data" => %{"dob" => "01/01/1970"}}

      {:ok, redirected_live, _} =
        view
        |> form("#profile-form", changes)
        |> render_submit()
        |> follow_redirect(conn)

      assert_role_text(redirected_live, "date-of-birth", "01/01/1970")
      assert [%{source: "form", dob: ~D[1970-01-01]}] = Cases.get_person(person.id, user) |> Cases.preload_demographics() |> Map.get(:demographics)
    end

    test "dob field retains invalid date after failed validation, rather than resetting to the value from the database", %{conn: conn, person: person} do
      view = Pages.ProfileEdit.visit(conn, person)

      assert_attribute(view, "input[data-role=dob]", "value", ["01/01/2000"])

      rendered = view |> form("#profile-form", form_data: %{"dob" => "Jan 4 1928"}) |> render_submit()

      assert_attribute(view, "input[data-role=dob]", "value", ["Jan 4 1928"])
      Pages.assert_validation_messages(rendered, %{"form_data[dob]" => "please enter dates as mm/dd/yyyy"})
    end

    test "validation shows informative message when phi is entered in a non-phi environment", %{conn: conn, person: person} do
      view = Pages.ProfileEdit.visit(conn, person)

      assert_attribute(view, "input[data-role=dob]", "value", ["01/01/2000"])

      rendered = view |> form("#profile-form", form_data: %{"dob" => "01/03/2000"}) |> render_submit()

      assert_attribute(view, "input[data-role=dob]", "value", ["01/03/2000"])
      Pages.assert_validation_messages(rendered, %{"form_data[dob]" => "In non-PHI environment, must be the first of the month"})
    end

    test "editing person identifying information works, saves an audit trail, and redirects to the profile page", %{conn: conn, person: person} do
      view = Pages.ProfileEdit.visit(conn, person)

      {:ok, redirected_view, _} =
        view
        |> form("#profile-form",
          form_data: %{first_name: "Aaron", last_name: "Testuser2", dob: "01/01/2020", preferred_language: "French"}
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert_role_text(redirected_view, "full-name", "Aaron Testuser2")
      assert_role_text(redirected_view, "date-of-birth", "01/01/2020")
      assert_role_text(redirected_view, "preferred-language", "French")
    end

    test "editing preferred language with other option", %{conn: conn, person: person} do
      view = Pages.ProfileEdit.visit(conn, person)

      {:ok, redirected_live, _} =
        view
        |> form("#profile-form",
          form_data: %{
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
      view = Pages.ProfileEdit.visit(conn, person)
      assert_selected_dropdown_option(view: view, data_role: "preferred-language", expected: ["Welsh"])
      assert_attribute(view, "[data-role=other-preferred-language]", "data-disabled", ["data-disabled"])
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes the name", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.change_form(%{"first_name" => "New Name"})
      |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")
    end

    test "when the user changes the dob", %{conn: conn, person: person} do
      # this case is special because the rendered dob is different than the db formatted dob
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.change_form(%{"dob" => "07/01/2001"})
      |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")
    end

    test "when the preferred language is other", %{conn: conn, person: person} do
      view = Pages.ProfileEdit.visit(conn, person)

      view
      |> form("#profile-form")
      |> render_change(
        form_data: %{
          first_name: "Aaron",
          last_name: "Testuser2",
          dob: "01/01/2020",
          preferred_language: "Other",
          other_specified_language: "Welsh"
        }
      )

      view |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")
    end
  end

  describe "addresses" do
    test "adding address to a person", %{conn: conn, person: person, user: user} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_address_form(%{})
      |> Pages.ProfileEdit.click_add_address_button()
      |> Pages.submit_and_follow_redirect(conn, "#profile-form",
        form_data: %{
          "addresses" => %{"0" => %{"street" => "1001 Test St", "city" => "City", "state" => "OH", "postal_code" => "00000"}}
        }
      )
      |> Pages.Profile.assert_addresses(["1001 Test St, City, OH 00000"])

      Cases.get_person(person.id, user)
      |> Cases.preload_addresses()
      |> Map.get(:addresses)
      |> pluck([:street, :city, :state, :postal_code])
      |> assert_eq([
        %{
          street: "1001 Test St",
          city: "City",
          state: "OH",
          postal_code: "00000"
        }
      ])
    end

    test "updating existing addresses", %{conn: conn, person: person, user: user} do
      Test.Fixtures.address_attrs(user, person, "address-1", 5555) |> Cases.create_address!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_address_form(%{"form_data[addresses][0][street]" => "5555 Test St"})
      |> Pages.submit_and_follow_redirect(conn, "#profile-form",
        form_data: %{
          "addresses" => %{"0" => %{"street" => "1001 Test St", "city" => "City", "state" => "OH", "postal_code" => "00000"}}
        }
      )
      |> Pages.Profile.assert_addresses(["1001 Test St, City, OH 00000"])

      Cases.get_person(person.id, user)
      |> Cases.preload_addresses()
      |> Map.get(:addresses)
      |> pluck([:street, :city, :state, :postal_code])
      |> assert_eq([
        %{
          street: "1001 Test St",
          city: "City",
          state: "OH",
          postal_code: "00000"
        }
      ])
    end

    test "updating existing addresses state only", %{conn: conn, person: person, user: user} do
      Test.Fixtures.address_attrs(user, person, "address-1", 5555) |> Cases.create_address!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_address_form(%{"form_data[addresses][0][street]" => "5555 Test St"})
      |> Pages.submit_and_follow_redirect(conn, "#profile-form",
        form_data: %{
          "addresses" => %{"0" => %{"state" => "AK"}}
        }
      )
      |> Pages.Profile.assert_addresses(["5555 Test St, City, AK 00000"])

      Cases.get_person(person.id, user)
      |> Cases.preload_addresses()
      |> Map.get(:addresses)
      |> pluck([:street, :city, :state, :postal_code])
      |> assert_eq([
        %{
          street: "5555 Test St",
          city: "City",
          state: "AK",
          postal_code: "00000"
        }
      ])
    end

    test "clicking add address button does not reset state of form", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.click_add_address_button()
      |> Pages.ProfileEdit.change_form(%{"addresses" => %{"0" => %{"street" => "3322 Test St"}}})
      |> Pages.ProfileEdit.click_add_address_button()
      |> Pages.ProfileEdit.assert_address_form(%{"form_data[addresses][0][street]" => "3322 Test St", "form_data[addresses][1][street]" => ""})
      |> Pages.assert_validation_messages(%{})
    end

    test "it doesn't save empty addresses", %{conn: conn, person: person, user: user} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_address_form(%{})
      |> Pages.ProfileEdit.click_add_address_button()
      |> Pages.submit_and_follow_redirect(conn, "#profile-form",
        form_data: %{
          "addresses" => %{"0" => %{"street" => "", "city" => "", "state" => "OH", "postal_code" => ""}}
        }
      )

      Cases.get_person(person.id, user)
      |> Cases.preload_addresses()
      |> Map.get(:addresses)
      |> assert_eq([])
    end
  end

  describe "email addresses" do
    test "adding email address to a person", %{conn: conn, person: person, user: user} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_email_form(%{})
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.submit_and_follow_redirect(conn, "#profile-form", form_data: %{"emails" => %{"0" => %{"address" => "alice@example.com"}}})
      |> Pages.Profile.assert_email_addresses(["alice@example.com"])

      Cases.get_person(person.id, user) |> Cases.preload_emails() |> Map.get(:emails) |> pluck(:address) |> assert_eq(["alice@example.com"])
    end

    @tag :skip
    test "adding preferred email address", %{conn: conn, person: person, user: user} do
      Test.Fixtures.email_attrs(user, person, "alice-a") |> Cases.create_email!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_email_form(%{"form_data[emails][0][address]" => "alice-a@example.com"})
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.submit_and_follow_redirect(conn, "#profile-form",
        form_data: %{
          "emails" => %{
            "0" => %{"address" => "alice-a@example.com", "is_preferred" => "false"},
            "1" => %{"address" => "alice-preferred@example.com", "is_preferred" => "true"}
          }
        }
      )
      |> Pages.Profile.assert_email_addresses(["alice-a@example.com", "alice-preferred@example.com"])
    end

    test "updating existing email address", %{conn: conn, person: person, user: user} do
      Test.Fixtures.email_attrs(user, person, "alice-a") |> Cases.create_email!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_email_form(%{"form_data[emails][0][address]" => "alice-a@example.com"})
      |> Pages.submit_and_follow_redirect(conn, "#profile-form", form_data: %{"emails" => %{"0" => %{"address" => "alice-b@example.com"}}})
      |> Pages.Profile.assert_email_addresses(["alice-b@example.com"])
    end

    test "deleting existing email address", %{conn: conn, person: person, user: user} do
      Test.Fixtures.email_attrs(user, person, "alice-a") |> Cases.create_email!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_email_form(%{"form_data[emails][0][address]" => "alice-a@example.com"})
      |> Pages.ProfileEdit.click_remove_email_button(index: "0")
      |> Pages.ProfileEdit.assert_email_form(%{})
      |> Pages.submit_and_follow_redirect(conn, "#profile-form", form_data: %{"emails" => %{}})
      |> Pages.Profile.assert_email_addresses(["Unknown"])

      Cases.get_person(person.id, user) |> Cases.preload_emails() |> Map.get(:emails) |> assert_eq([])
    end

    test "blank email addresses are ignored (rather than being validation errors)", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.submit_and_follow_redirect(conn, "#profile-form",
        form_data: %{
          "emails" => %{"0" => %{"address" => "alice-0@example.com"}, "1" => %{"address" => ""}}
        }
      )
      |> Pages.Profile.assert_email_addresses(["alice-0@example.com"])
    end

    test "clicking add email address button does not reset state of form", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.change_form(%{"emails" => %{"0" => %{"address" => "alice-0@example.com"}}})
      |> Pages.ProfileEdit.click_add_email_button()
      |> Pages.ProfileEdit.assert_email_form(%{"form_data[emails][0][address]" => "alice-0@example.com", "form_data[emails][1][address]" => ""})
      |> Pages.assert_validation_messages(%{})
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
    test "adding phone number to a person", %{conn: conn, person: person, user: user} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_phone_number_form(%{})
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.ProfileEdit.assert_phone_number_types("phone-types", ["Unknown", "Cell", "Home", "Work"])
      |> Pages.submit_and_follow_redirect(conn, "#profile-form", form_data: %{"phones" => %{"0" => %{"number" => "1111111000", "type" => "cell"}}})
      |> Pages.Profile.assert_phone_numbers(["(111) 111-1000"])

      phones = Cases.get_person(person.id, user) |> Cases.preload_phones() |> Map.get(:phones)
      phones |> pluck(:number) |> assert_eq(["1111111000"])
      phones |> pluck(:type) |> assert_eq(["cell"])
    end

    test "updating existing phone numbers", %{conn: conn, person: person, user: user} do
      Test.Fixtures.phone_attrs(user, person, "phone-1", number: "111-111-1000") |> Cases.create_phone!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_phone_number_form(%{"form_data[phones][0][number]" => "1111111000"})
      |> Pages.submit_and_follow_redirect(conn, "#profile-form", form_data: %{"phones" => %{"0" => %{"number" => "11111111009"}}})
      |> Pages.Profile.assert_phone_numbers(["+1 (111) 111-1009"])

      phones = Cases.get_person(person.id, user) |> Cases.preload_phones() |> Map.get(:phones)
      phones |> pluck(:number) |> assert_eq(["11111111009"])
    end

    test "deleting existing phone numbers", %{conn: conn, person: person, user: user} do
      Test.Fixtures.phone_attrs(user, person, "phone-1", number: "111-111-1000") |> Cases.create_phone!()

      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.assert_phone_number_form(%{"form_data[phones][0][number]" => "1111111000"})
      |> Pages.ProfileEdit.click_remove_phone_button(index: "0")
      |> Pages.ProfileEdit.assert_phone_number_form(%{})
      |> Pages.submit_and_follow_redirect(conn, "#profile-form", form_data: %{"phones" => %{}})
      |> Pages.Profile.assert_phone_numbers(["Unknown"])

      Cases.get_person(person.id, user) |> Cases.preload_phones() |> Map.get(:phones) |> assert_eq([])
    end

    test "blank phone numbers are ignored (rather than being validation errors)", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.submit_and_follow_redirect(conn, "#profile-form",
        form_data: %{
          "phones" => %{"0" => %{"number" => "1111111001"}, "1" => %{"number" => ""}}
        }
      )
      |> Pages.Profile.assert_phone_numbers(["(111) 111-1001"])
    end

    test "clicking phone number button does not reset state of form", %{conn: conn, person: person} do
      Pages.ProfileEdit.visit(conn, person)
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.ProfileEdit.change_form(%{"phones" => %{"0" => %{"number" => "1111111001"}}})
      |> Pages.ProfileEdit.click_add_phone_button()
      |> Pages.ProfileEdit.assert_phone_number_form(%{"form_data[phones][0][number]" => "1111111001", "form_data[phones][1][number]" => ""})
      |> Pages.assert_validation_messages(%{})
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

  describe "states" do
    test "returns a list of states tuples" do
      "TS"
      |> ProfileEditLive.states()
      |> Enum.each(fn
        {"", nil} ->
          # pass
          nil

        state_tuple ->
          assert {state, state} = state_tuple
      end)
    end

    test "includes the passed-in current state" do
      assert {"TS", "TS"} in ProfileEditLive.states("TS")
    end

    test "includes blank state" do
      assert {"", nil} in ProfileEditLive.states(nil)
      assert {"", nil} in ProfileEditLive.states("TS")
    end

    test "does not duplicate existing states" do
      ProfileEditLive.states("OH")
      |> Enum.count(fn state_tuple -> {"OH", "OH"} == state_tuple end)
      |> assert_eq(1)
    end
  end
end
