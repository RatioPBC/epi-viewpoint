defmodule EpiViewpointWeb.Test.Pages.ProfileEdit do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.LiveViewAssertions
  alias EpiViewpointWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def change_form(%View{} = view, person_params) do
    view
    |> form("#profile-form", form_data: person_params)
    |> render_change()

    view
  end

  def submit(%View{} = view, person_params) do
    view
    |> form("#profile-form", form_data: person_params)
    |> render_submit()

    view |> Pages.assert_validation_messages(%{})
  end

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}) do
    conn |> Pages.visit("/people/#{person_id}/edit")
  end

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("profile-edit")

  #
  # address
  #

  def assert_address_form(%View{} = view, expected_addresses) do
    assert addresses(view) == expected_addresses
    view
  end

  def click_add_address_button(%View{} = view) do
    view |> render_click("add-address")
    view
  end

  def addresses(%View{} = view) do
    view
    |> Pages.parse()
    |> Test.Html.all("[data-role=street-input]", fn element ->
      {Test.Html.attr(element, "name") |> Euclid.Extra.List.first(), Test.Html.attr(element, "value") |> Euclid.Extra.List.first("")}
    end)
    |> Map.new()
  end

  def click_remove_address_button(%View{} = view, index: index) do
    view |> render_click("remove-address", %{"address-index" => index})
    view
  end

  #
  # email address
  #

  def assert_email_form(%View{} = view, expected_email_addresses) do
    assert email_addresses(view) == expected_email_addresses
    view
  end

  def assert_email_label_present(%View{} = view) do
    assert view |> email_address_label() == "Email"
    view
  end

  def click_add_email_button(%View{} = view) do
    view |> render_click("add-email")
    view
  end

  def click_remove_email_button(%View{} = view, index: index) do
    view |> render_click("remove-email", %{"email-index" => index})
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

  def email_address_label(%View{} = view) do
    view |> Pages.parse() |> Test.Html.text("[data-role=email-fieldset-header]")
  end

  def refute_email_label_present(%View{} = view) do
    assert view |> email_address_label() == ""
    view
  end

  #
  # phone number
  #

  def assert_phone_number_form(%View{} = view, expected_phone_numbers) do
    assert phone_numbers(view) == expected_phone_numbers
    view
  end

  def assert_phone_number_types(%View{} = view, data_role, expected) do
    LiveViewAssertions.assert_select_dropdown_options(view: view, data_role: data_role, expected: expected)
    view
  end

  def click_add_phone_button(%View{} = view) do
    view |> render_click("add-phone")
    view
  end

  def click_remove_phone_button(%View{} = view, index: index) do
    view |> render_click("remove-phone", %{"phone-index" => index})
    view
  end

  def phone_numbers(%View{} = view) do
    view
    |> Pages.parse()
    |> Test.Html.all("[data-role=phone-input]", fn element ->
      {Test.Html.attr(element, "name") |> Euclid.Extra.List.first(), Test.Html.attr(element, "value") |> Euclid.Extra.List.first("")}
    end)
    |> Map.new()
  end
end
