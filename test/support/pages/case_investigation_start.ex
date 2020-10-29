defmodule EpicenterWeb.Test.Pages.CaseInvestigationStart do
  import ExUnit.Assertions

  alias Epicenter.Cases.Person
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}) do
    conn |> Pages.visit("/people/#{person_id}/case_investigations/todo/start")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-start")
    view_or_conn_or_html
  end

  def assert_person_interviewed_selections(%View{} = view, expected_selections) do
    assert Pages.actual_selections(view, "case-investigation-person-interview", "checkbox") == expected_selections
    view
  end
end
