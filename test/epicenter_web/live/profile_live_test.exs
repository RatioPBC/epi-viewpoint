defmodule EpicenterWeb.ProfileLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.ProfileLive

  setup do
    user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
    person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
    [person: person, user: user]
  end

  test "disconnected and connected render", %{conn: conn, person: person} do
    {:ok, page_live, disconnected_html} = live(conn, "/people/#{person.id}")

    assert_has_role(disconnected_html, "profile-page")
    assert_has_role(page_live, "profile-page")
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

    test("email_addresses", %{person: person}, do: person |> ProfileLive.email_addresses() |> assert_eq([]))

    test("phone_numbers", %{person: person}, do: person |> ProfileLive.phone_numbers() |> assert_eq([]))
  end

  describe "when the person has identifying information" do
    setup %{person: person} do
      Test.Fixtures.email_attrs(person, "alice-a") |> Cases.create_email!()
      Test.Fixtures.email_attrs(person, "alice-preferred", is_preferred: true) |> Cases.create_email!()
      Test.Fixtures.phone_attrs(person, "phone-1", number: 1_111_111_000) |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(person, "phone-2", number: 1_111_111_001, is_preferred: true) |> Cases.create_phone!()
      Test.Fixtures.address_attrs(person, "alice-address", 1000, type: "home") |> Cases.create_address!()
      Test.Fixtures.address_attrs(person, "alice-address-preferred", 2000, type: nil, is_preferred: true) |> Cases.create_address!()
      :ok
    end

    test "showing person identifying information", %{conn: conn, person: person} do
      {:ok, page_live, _html} = live(conn, "/people/#{person.id}")

      assert_role_text(page_live, "full-name", "Alice Testuser")
      assert_role_text(page_live, "date-of-birth", "01/01/2000")
      assert_role_text(page_live, "preferred-language", "English")
      assert_role_text(page_live, "phone-number", "111-111-1001 111-111-1000")
      assert_role_text(page_live, "email-address", "alice-preferred@example.com alice-a@example.com")
      assert_role_text(page_live, "address", "2000 Test St, City, TS 00000 1000 Test St, City, TS 00000 home")
    end

    test "email_addresses", %{person: person} do
      person |> ProfileLive.email_addresses() |> assert_eq(["alice-preferred@example.com", "alice-a@example.com"])
    end

    test "phone_numbers", %{person: person} do
      person |> ProfileLive.phone_numbers() |> assert_eq(["111-111-1001", "111-111-1000"])
    end
  end

  describe "when the person has no test results" do
    test "renders no lab result text", %{conn: conn, person: person} do
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
      })
      |> Cases.create_lab_result!()

      :ok
    end

    test "lab result table", %{conn: conn, person: person} do
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

  describe "assigning and unassigning user to a person" do
    defp table_contents(live, opts),
      do: live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "people"))

    setup %{person: person} do
      Test.Fixtures.address_attrs(person, "address1", 1000) |> Cases.create_address!()
      Test.Fixtures.lab_result_attrs(person, "lab1", ~D[2020-04-10]) |> Cases.create_lab_result!()
      assignee = Test.Fixtures.user_attrs("assignee") |> Accounts.create_user!()
      [person: person, assignee: assignee]
    end

    test "assign_person", %{assignee: assignee, person: alice, user: user} do
      {:ok, [alice]} = Cases.assign_user_to_people(user_id: assignee.id, people_ids: [alice.id], originator: user)
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
      index_page_live |> element("[data-role=#{alice.tid}]") |> render_click(%{"person-id" => alice.id, "value" => "on"})
      index_page_live |> element("[data-role=#{billy.tid}]") |> render_click(%{"person-id" => billy.id, "value" => "on"})
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

    test "handles {:people, updated_people} when csv upload includes new values", %{conn: conn, person: alice} do
      socket = %Phoenix.LiveView.Socket{assigns: %{person: alice}}
      {:ok, show_page_live, _html} = live(conn, "/people/#{alice.id}")
      assert_role_text(show_page_live, "address", "1000 Test St, City, TS 00000 home")

      Test.Fixtures.address_attrs(alice, "address2", 2000) |> Cases.create_address!()
      {:noreply, updated_socket} = ProfileLive.handle_info({:people, [%{alice | tid: "updated-alice"}]}, socket)
      assert updated_socket.assigns.person.tid == "updated-alice"
      assert updated_socket.assigns.person.addresses |> tids() == ["address1", "address2"]
    end
  end
end
