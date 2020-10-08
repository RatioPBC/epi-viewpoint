defmodule EpicenterWeb.ProfileLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.ProfileLive
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    [person: person, user: user]
  end

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}")

    assert_has_role(disconnected_html, "profile-page")
    assert_has_role(page_live, "profile-page")
  end

  describe "when the person has no identifying information" do
    test "showing person identifying information", %{conn: conn, person: person, user: user} do
      {:ok, _} = Cases.update_person(person, {%{preferred_language: nil}, Test.Fixtures.audit_meta(user)})
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "preferred-language", "Unknown")
      assert_role_text(page_live, "phone-numbers", "Unknown")
      assert_role_text(page_live, "email-addresses", "Unknown")
      assert_role_text(page_live, "address", "Unknown")
    end

    test("email_addresses", %{person: person}, do: person |> ProfileLive.email_addresses() |> assert_eq([]))

    test("phone_numbers", %{person: person}, do: person |> ProfileLive.phone_numbers() |> assert_eq([]))
  end

  describe "when the person has identifying information" do
    setup %{person: person, user: user} do
      Test.Fixtures.email_attrs(user, person, "alice-a") |> Cases.create_email!()
      Test.Fixtures.email_attrs(user, person, "alice-preferred", is_preferred: true) |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, person, "phone-1", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(user, person, "phone-2", number: "111-111-1001", is_preferred: true) |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, person, "alice-address", 1000, type: "home") |> Cases.create_address!()
      Test.Fixtures.address_attrs(user, person, "alice-address-preferred", 2000, type: nil, is_preferred: true) |> Cases.create_address!()
      :ok
    end

    test "showing person identifying information", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "full-name", "Alice Testuser")
      assert_role_text(page_live, "date-of-birth", "01/01/2000")
      assert_role_text(page_live, "preferred-language", "English")
      assert_role_text(page_live, "phone-numbers", "111-111-1001 111-111-1000")
      assert_role_text(page_live, "email-addresses", "alice-preferred@example.com alice-a@example.com")
      assert_role_text(page_live, "address", "2000 Test St, City, TS 00000 1000 Test St, City, TS 00000 home")
    end

    test "email_addresses", %{person: person} do
      person |> ProfileLive.email_addresses() |> assert_eq(["alice-preferred@example.com", "alice-a@example.com"])
    end

    test "phone_numbers", %{person: person, user: user} do
      Test.Fixtures.phone_attrs(user, person, "phone-3", number: "1-111-111-1009") |> Cases.create_phone!()
      person |> ProfileLive.phone_numbers() |> assert_eq(["111-111-1001", "111-111-1000", "1-111-111-1009"])
    end
  end

  describe "when the person has no test results" do
    test "renders no lab result text", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      page_live
      |> assert_role_text("lab-results", "Lab Results No lab results")
    end
  end

  describe "lab results table" do
    defp build_lab_result(person, user, tid, sampled_on, analyzed_on, reported_on) do
      Test.Fixtures.lab_result_attrs(person, user, tid, sampled_on, %{
        result: "positive",
        request_facility_name: "Big Big Hospital",
        analyzed_on: analyzed_on,
        reported_on: reported_on,
        test_type: "PCR"
      })
      |> Cases.create_lab_result!()
    end

    test "shows lab results", %{conn: conn, person: person, user: user} do
      build_lab_result(person, user, "lab1", ~D[2020-04-10], ~D[2020-04-11], ~D[2020-04-12])
      build_lab_result(person, user, "lab2", ~D[2020-04-12], ~D[2020-04-13], ~D[2020-04-14])

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_lab_results([
        ["Collection", "Result", "Ordering Facility", "Analysis", "Reported", "Type"],
        ["04/12/2020", "positive", "Big Big Hospital", "04/13/2020", "04/14/2020", "PCR"],
        ["04/10/2020", "positive", "Big Big Hospital", "04/11/2020", "04/12/2020", "PCR"]
      ])
    end

    test "orders by sampled_on (desc) and then reported_on (desc)", %{conn: conn, person: person, user: user} do
      build_lab_result(person, user, "lab4", ~D[2020-04-13], ~D[2020-04-20], ~D[2020-04-26])
      build_lab_result(person, user, "lab1", ~D[2020-04-15], ~D[2020-04-20], ~D[2020-04-25])
      build_lab_result(person, user, "lab3", ~D[2020-04-14], ~D[2020-04-20], ~D[2020-04-23])
      build_lab_result(person, user, "lab2", ~D[2020-04-14], ~D[2020-04-20], ~D[2020-04-24])

      Pages.Profile.visit(conn, person)
      |> Pages.Profile.assert_lab_results(
        [columns: ["Collection", "Reported"], tids: true],
        [
          ["Collection", "Reported", :tid],
          ["04/15/2020", "04/25/2020", "lab1"],
          ["04/14/2020", "04/24/2020", "lab2"],
          ["04/14/2020", "04/23/2020", "lab3"],
          ["04/13/2020", "04/26/2020", "lab4"]
        ]
      )
    end
  end

  describe "assigning and unassigning user to a person" do
    defp table_contents(live, opts),
      do: live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "people"))

    setup %{person: person, user: user} do
      Test.Fixtures.address_attrs(user, person, "address1", 1000) |> Cases.create_address!()
      Test.Fixtures.lab_result_attrs(person, user, "lab1", ~D[2020-04-10]) |> Cases.create_lab_result!()
      assignee = Test.Fixtures.user_attrs(Test.Fixtures.admin(), "assignee") |> Accounts.register_user!()
      [person: person, assignee: assignee]
    end

    test "assign_person", %{assignee: assignee, person: alice, user: user} do
      {:ok, [alice]} =
        Cases.assign_user_to_people(
          user_id: assignee.id,
          people_ids: [alice.id],
          audit_meta: Test.Fixtures.audit_meta(user)
        )

      updated_socket = %Phoenix.LiveView.Socket{assigns: %{person: alice}} |> ProfileLive.assign_person(alice)
      assert updated_socket.assigns.person.addresses |> tids() == ["address1"]
      assert updated_socket.assigns.person.assigned_to.tid == "assignee"
      assert updated_socket.assigns.person.lab_results |> tids() == ["lab1"]
      assert updated_socket.assigns.person.tid == "alice"
    end

    test "people can be assigned to users on index and show page, with cross-client updating", %{conn: conn, person: alice, assignee: assignee} do
      billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()

      {:ok, index_page_live, _html} = live(conn, "/people")
      {:ok, show_page_live, _html} = live(conn, "/people/#{alice.id}")

      index_page_live
      |> table_contents(columns: ["Name", "Assignee"])
      |> assert_eq([
        ["Name", "Assignee"],
        ["Alice Testuser", ""],
        ["Billy Testuser", ""]
      ])

      # choose "assignee" via show page
      assert_select_dropdown_options(view: show_page_live, data_role: "users", expected: ["Unassigned", "assignee", "user"])
      show_page_live |> element("#assignment-form") |> render_change(%{"user" => assignee.id})
      assert_selected_dropdown_option(view: show_page_live, data_role: "users", expected: ["assignee"])
      assert Cases.get_person(alice.id) |> Cases.preload_assigned_to() |> Map.get(:assigned_to) |> Map.get(:tid) == "assignee"

      # "assignee" shows up on index page
      index_page_live
      |> table_contents(columns: ["Name", "Assignee"])
      |> assert_eq([
        ["Name", "Assignee"],
        ["Alice Testuser", "assignee"],
        ["Billy Testuser", ""]
      ])

      # unassign "assignee" via show page
      show_page_live |> element("#assignment-form") |> render_change(%{"user" => "-unassigned-"})
      assert_selected_dropdown_option(view: show_page_live, data_role: "users", expected: ["Unassigned"])
      assert Cases.get_person(alice.id) |> Cases.preload_assigned_to() |> Map.get(:assigned_to) == nil

      # "assignee" disappears from index page
      index_page_live
      |> table_contents(columns: ["Name", "Assignee"])
      |> assert_eq([
        ["Name", "Assignee"],
        ["Alice Testuser", ""],
        ["Billy Testuser", ""]
      ])

      # choose "assignee" via index page
      index_page_live |> element("[data-tid=#{alice.tid}]") |> render_click(%{"person-id" => alice.id, "value" => "on"})
      index_page_live |> element("[data-tid=#{billy.tid}]") |> render_click(%{"person-id" => billy.id, "value" => "on"})
      index_page_live |> element("#assignment-form") |> render_change(%{"user" => assignee.id})

      assert_selected_dropdown_option(view: show_page_live, data_role: "users", expected: ["assignee"])
    end

    test "handles assign_users message when the changed people include the current person", %{person: alice, assignee: assignee} do
      billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()
      socket = %Phoenix.LiveView.Socket{assigns: %{person: alice}}

      {:noreply, updated_socket} = ProfileLive.handle_info({:people, [%{alice | tid: "updated-alice"}, billy]}, socket)
      assert updated_socket.assigns.person.tid == "updated-alice"
    end

    test "handles assign_users message when the changed people do not include the current person", %{person: alice, assignee: assignee} do
      billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()
      socket = %Phoenix.LiveView.Socket{assigns: %{person: alice}}

      {:noreply, updated_socket} = ProfileLive.handle_info({:people, [%{billy | tid: "updated-billy"}]}, socket)
      assert updated_socket.assigns.person.tid == "alice"
    end

    test "handles {:people, updated_people} when csv upload includes new values", %{conn: conn, person: alice, user: user} do
      socket = %Phoenix.LiveView.Socket{assigns: %{person: alice}}
      {:ok, show_page_live, _html} = live(conn, "/people/#{alice.id}")
      assert_role_text(show_page_live, "address", "1000 Test St, City, TS 00000 home")

      Test.Fixtures.address_attrs(user, alice, "address2", 2000) |> Cases.create_address!()
      {:noreply, updated_socket} = ProfileLive.handle_info({:people, [%{alice | tid: "updated-alice"}]}, socket)
      assert updated_socket.assigns.person.tid == "updated-alice"
      assert updated_socket.assigns.person.addresses |> tids() == ["address1", "address2"]
    end
  end

  describe "demographics" do
    setup %{person: person, user: user} do
      person_attrs = Test.Fixtures.add_demographic_attrs(%{})
      Cases.update_person(person, {person_attrs, Test.Fixtures.audit_meta(user)})
      :ok
    end

    test "showing person demographics", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "gender-identity", "Female")
      assert_role_text(page_live, "sex-at-birth", "Female")
      assert_role_text(page_live, "ethnicity", "Not Hispanic, Latino/a, or Spanish origin")
      assert_role_text(page_live, "race", "Filipino")
      assert_role_text(page_live, "marital-status", "Single")
      assert_role_text(page_live, "employment", "Part time")
      assert_role_text(page_live, "occupation", "architect")
      assert_role_text(page_live, "notes", "lorem ipsum")
    end

    @tag :skip
    test "navigating to edit demographics", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      page_live
      |> element("[data-role=edit-demographics-button]")
      |> render_click()
      |> assert_redirects_to("/people/#{person.id}/edit-demographics")
    end

    defp assert_redirects_to({_, {:live_redirect, %{to: destination_path}}}, expected_path) do
      assert destination_path == expected_path
    end
  end
end
