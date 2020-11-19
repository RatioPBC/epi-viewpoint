defmodule EpicenterWeb.Test.Pages.People do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias EpicenterWeb.Test.LiveViewAssertions
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn),
    do: conn |> Pages.visit("/people")

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("people")

  def assign(%View{} = view, people, user) do
    for person <- people do
      view |> element("[data-tid=#{person.tid}]") |> render_click(%{"person-id" => person.id, "value" => "on"})
    end

    view |> element("#assignment-form") |> render_change(%{"user" => user.id})
    view
  end

  def assignees(%View{} = view) do
    view
    |> Pages.parse()
    |> Test.Table.table_contents(columns: ["Name", "Assignee"], headers: false, role: "people")
    |> Enum.map(fn [name, assignee] -> {name, assignee} end)
    |> Enum.into(%{})
  end

  def assert_assignees(%View{} = view, expected_assignees) do
    assert view |> assignees() == expected_assignees
    view
  end

  def assert_assign_dropdown_options(%View{} = view, data_role: data_role, expected: expected) do
    LiveViewAssertions.assert_select_dropdown_options(view: view, data_role: data_role, expected: expected)
    view
  end

  def assert_checked(%View{} = view, selector) do
    LiveViewAssertions.assert_attribute(view, selector, "checked", ["checked"])
    view
  end

  def assert_filter_selected(%View{} = view, filter_name) do
    LiveViewAssertions.assert_attribute(view, "[data-role=people-filter][data-tid=#{filter_name}]", "data-active", ["true"])
    view
  end

  def assert_reload_message(%View{} = view, expected_value) do
    LiveViewAssertions.assert_role_text(view, "reload-message", expected_value)
    view
  end

  def assert_table_contents(%View{} = view, expected_table_content, opts \\ []) do
    assert table_contents(view, opts) == expected_table_content
    view
  end

  def assert_unchecked(%View{} = view, selector) do
    LiveViewAssertions.assert_attribute(view, selector, "checked", [])
    view
  end

  def click_assigned_to_me_checkbox(%View{} = view) do
    view |> element("[data-tid=assigned-to-me-checkbox]") |> render_click()
    view
  end

  def click_person_checkbox(%View{} = view, person: person, value: value) do
    view |> element("[data-tid=#{person.tid}]") |> render_click(%{"person-id" => person.id, "value" => value})
    view
  end

  def click_reload_people(%View{} = view) do
    render_click(view, "reload-people")
    view
  end

  def change_form(%View{} = view, params) do
    view |> element("#assignment-form") |> render_change(params)
    view
  end

  def select_filter(%View{} = view, filter_name) do
    view |> element("[data-tid=#{filter_name}]") |> render_click()
    view
  end

  defp table_contents(index_live, opts),
    do: index_live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "people"))
end
