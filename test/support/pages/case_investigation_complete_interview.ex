defmodule EpicenterWeb.Test.Pages.CaseInvestigationCompleteInterview do
  import ExUnit.Assertions

  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: case_investigation_id}) do
    conn |> Pages.visit("/case_investigations/#{case_investigation_id}/complete_interview")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-complete")
  end

  def assert_date_completed(%View{} = view, :today) do
    [actual_date] = actual_date_completed(view)

    assert actual_date =~ ~r"\d\d\/\d\d\/\d\d\d\d"
    view
  end

  def assert_date_completed(%View{} = view, expected_date_string) do
    [actual_date] = actual_date_completed(view)

    assert actual_date == expected_date_string
    view
  end

  defp actual_date_completed(%View{} = view) do
    view
    |> Pages.parse()
    |> Test.Html.find("input#complete_interview_form_date_completed")
    |> Test.Html.attr("value")
  end

  def assert_time_completed(%View{} = view, :now) do
    {actual_time, actual_am_pm} = actual_time_completed(view)

    assert actual_time =~ ~r"\d\d:\d\d"
    assert actual_am_pm in ~w{AM PM}
    view
  end

  def assert_time_completed(%View{} = view, expected_time, expected_am_pm) do
    {actual_time, actual_am_pm} = actual_time_completed(view)

    assert actual_time == expected_time
    assert actual_am_pm == expected_am_pm
    view
  end

  defp actual_time_completed(view) do
    parsed = view |> Pages.parse()

    [actual_time] =
      parsed
      |> Test.Html.find("input#complete_interview_form_time_completed")
      |> Test.Html.attr("value")

    [actual_am_pm] =
      parsed
      |> Test.Html.find("select#complete_interview_form_time_completed_am_pm option[selected]")
      |> Enum.map(&Test.Html.text(&1))

    {actual_time, actual_am_pm}
  end
end
