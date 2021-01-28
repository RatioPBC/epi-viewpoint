defmodule EpicenterWeb.Test.Pages.PotentialDuplicates do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias EpicenterWeb.Test.LiveViewAssertions
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}, extra_arg \\ nil) do
    conn |> Pages.visit("/people/#{person_id}/potential-duplicates", extra_arg)
  end

  def assert_here(view_or_conn_or_html, person) do
    view_or_conn_or_html |> Pages.assert_on_page("potential-duplicates")
    if !person.tid, do: raise("Person must have a tid for this assertion: #{inspect(person)}")
    view_or_conn_or_html |> Pages.parse() |> Test.Html.attr("[data-page=potential-duplicates]", "data-tid") |> assert_eq([person.tid])
    view_or_conn_or_html
  end

  def assert_merge_button_disabled(%View{} = view) do
    LiveViewAssertions.assert_disabled(view, "[data-role=merge-button]")
    view
  end

  def assert_merge_button_enabled(%View{} = view) do
    LiveViewAssertions.assert_enabled(view, "[data-role=merge-button]")
    view
  end

  def assert_table_contents(%View{} = view, expected_table_content, opts \\ []) do
    assert table_contents(view, opts) == expected_table_content
    view
  end

  def set_selected_people(%View{} = view, people) do
    view
    |> form("#records-to-merge-form")
    |> render_change(%{"selected_people" => Euclid.Extra.Enum.pluck(people, :id)})

    view
  end

  def submit_merge(%View{} = view) do
    view |> form("#records-to-merge-form") |> render_submit()
  end

  def table_contents(view, opts),
    do: view |> render() |> Test.Html.parse_doc() |> Test.Table.table_contents(opts |> Keyword.merge(role: "duplicates"))
end
