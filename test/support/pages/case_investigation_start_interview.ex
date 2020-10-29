defmodule EpicenterWeb.Test.Pages.CaseInvestigationStartInterview do
  import ExUnit.Assertions

  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}) do
    conn |> Pages.visit("/people/#{person_id}/case_investigations/todo/start_interview")
  end

  def assert_date_started(%View{} = view, :today) do
    [actual_date] = view
                    |> Pages.parse()
                    |> Test.Html.find("input#start_interview_form_date_started")
                    |> Test.Html.attr("value")
    assert actual_date =~ ~r"\d\d\/\d\d\/\d\d\d\d"
    view
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-start-interview")
    view_or_conn_or_html
  end

  def assert_person_interviewed_selections(%View{} = view, expected_selections) do
    assert Pages.actual_selections(view, "start-interview-form-person-interviewed", "checkbox") == expected_selections
    view
  end
end
