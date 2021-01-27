defmodule EpicenterWeb.Test.Pages.Contacts do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias EpicenterWeb.Test.LiveViewAssertions
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def assert_assign_dropdown_options(%View{} = view, data_role: data_role, expected: expected) do
    LiveViewAssertions.assert_select_dropdown_options(view: view, data_role: data_role, expected: expected)
    view
  end

  def assert_assignment_dropdown_disabled(%View{} = view) do
    LiveViewAssertions.assert_disabled(view, "[data-role=users]")
    view
  end

  def assert_checked(%View{} = view, selector) do
    LiveViewAssertions.assert_attribute(view, selector, "checked", ["checked"])
    view
  end

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("contacts")

  def assert_table_contents(%View{} = view, expected_table_content, opts \\ []) do
    assert table_contents(view, opts) == expected_table_content
    view
  end

  def assert_filter_selected(%View{} = view, filter_name) do
    LiveViewAssertions.assert_attribute(view, "[data-role=contacts-filter][data-tid=#{filter_name}]", "data-active", ["true"])
    view
  end

  def assert_unchecked(%View{} = view, selector) do
    LiveViewAssertions.assert_attribute(view, selector, "checked", [])
    view
  end

  def assert_archive_button_disabled(%View{} = view) do
    LiveViewAssertions.assert_disabled(view, "[data-role=archive-button]")
    view
  end

  def change_form(%View{} = view, params) do
    view |> element("#assignment-form") |> render_change(params)
    view
  end

  def click_archive(%View{} = view) do
    view
    |> element("[data-role=archive-button]")
    |> render_click()

    view
  end

  def select_filter(%View{} = view, filter_name) do
    view |> element("[data-tid=#{filter_name}]") |> render_click()
    view
  end

  def click_person_checkbox(%View{} = view, person: person, value: value) do
    view |> element("[data-tid=#{person.tid}]") |> render_click(%{"person-id" => person.id, "value" => value})
    view
  end

  def visit(%Plug.Conn{} = conn),
    do: conn |> Pages.visit("/contacts")

  def click_to_person_profile(%View{} = view, person),
    do: view |> element("[data-role=profile-link-#{person.id}]") |> render_click()

  defp table_contents(index_live, opts),
    do: index_live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "contacts"))
end
