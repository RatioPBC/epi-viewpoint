defmodule EpicenterWeb.Test.Pages.ProfileEdit do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias EpicenterWeb.Test.LiveViewAssertions
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}) do
    conn |> Pages.visit("/people/#{person_id}/edit")
  end

  def assert_email_form(%View{} = view, expected_email_addresses) do
    assert email_addresses(view) == expected_email_addresses
    view
  end

  def email_addresses(%View{} = view) do
    view
    |> Pages.parse()
    |> Test.Html.all("[data-role=email-address-input]", fn element ->
      {Test.Html.attr(element, "name") |> Euclid.Extra.List.first(), Test.Html.attr(element, "value") |> Euclid.Extra.List.first("")}
    end)
    |> Map.new()
  end

  def assert_phone_number_form(%View{} = view, expected_phone_numbers) do
    assert phone_numbers(view) == expected_phone_numbers
    view
  end

  def phone_numbers(%View{} = view) do
    view
    |> Pages.parse()
    |> Test.Html.all("[data-role=phone-number-input]", fn element ->
      {Test.Html.attr(element, "name") |> Euclid.Extra.List.first(), Test.Html.attr(element, "value") |> Euclid.Extra.List.first("")}
    end)
    |> Map.new()
  end

  def email_address_label(%View{} = view) do
    view |> Pages.parse() |> Test.Html.text("[data-role=email-fieldset-header]")
  end

  def assert_email_label_present(%View{} = view) do
    assert view |> email_address_label() == "Email"
    view
  end

  def refute_email_label_present(%View{} = view) do
    assert view |> email_address_label() == ""
    view
  end

  def assert_validation_messages(%View{} = view, expected_messages) do
    view |> render() |> LiveViewAssertions.assert_validation_messages(expected_messages)
    view
  end

  def change_form(%View{} = view, person_params) do
    view
    |> form("#profile-form", person: person_params)
    |> render_change()

    view
  end

  def click_add_email_button(%View{} = view) do
    view |> render_click("add-email")
    view
  end

  def click_add_phone_button(%View{} = view) do
    view |> render_click("add-phone")
    view
  end

  def click_remove_email_button(%View{} = view, index: index) do
    view |> render_click("remove-email", %{"email-index" => index})
    view
  end

  def submit(%View{} = view, person_params) do
    view
    |> form("#profile-form", person: person_params)
    |> render_submit()

    view |> Pages.ProfileEdit.assert_validation_messages(%{})
  end

  def submit_and_follow_redirect(%View{} = view, conn, person_params) do
    {:ok, view, _} =
      view
      |> form("#profile-form", person: person_params)
      |> render_submit()
      |> Pages.follow_live_view_redirect(conn)

    view
  end
end
