defmodule EpicenterWeb.Test.Pages.People do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn) do
    conn |> Pages.visit("/people")
  end

  def assign(%View{} = view, people, user) do
    for person <- people do
      view |> element("[data-role=#{person.tid}]") |> render_click(%{"person-id" => person.id, "value" => "on"})
    end

    view |> element("#assignment-form") |> render_change(%{"user" => user.id})
    view
  end

  def assignees(%View{} = view) do
    view
    |> table_contents(columns: ["Name", "Assignee"], headers: false)
    |> Enum.map(fn [name, assignee] -> {name, assignee} end)
    |> Enum.into(%{})
  end

  def assert_assignees(%View{} = view, expected_assignees) do
    assert view |> assignees() == expected_assignees
    view
  end

  defp table_contents(live, opts),
    do: live |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "people"))
end
