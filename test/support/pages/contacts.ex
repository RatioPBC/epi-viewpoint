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

  def assert_unchecked(%View{} = view, selector) do
    LiveViewAssertions.assert_attribute(view, selector, "checked", [])
    view
  end

  def change_form(%View{} = view, params) do
    view |> element("#assignment-form") |> render_change(params)
    view
  end

  def click_person_checkbox(%View{} = view, person: person, value: value) do
    view |> element("[data-tid=#{person.tid}]") |> render_click(%{"person-id" => person.id, "value" => value})
    view
  end

  def visit(%Plug.Conn{} = conn),
    do: conn |> Pages.visit("/contacts")

  defp table_contents(index_live, opts),
    do: index_live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "contacts"))
end
