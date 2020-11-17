defmodule EpicenterWeb.Test.Pages.People do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
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

  def assert_table_contents(%View{} = view, expected_table_content) do
    assert table_contents(view) == expected_table_content
    view
  end

  defp table_contents(index_live, opts \\ []),
    do: index_live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "people"))
end
