defmodule EpiViewpointWeb.Test.Pages.CaseInvestigationStartInterview do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias EpiViewpoint.Cases.CaseInvestigation
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  @form_id "case-investigation-interview-start-form"

  def visit(%Plug.Conn{} = conn, %CaseInvestigation{id: case_investigation_id}) do
    conn |> Pages.visit("/case-investigations/#{case_investigation_id}/start-interview")
  end

  def assert_date_started(%View{} = view, :today) do
    [actual_date] =
      view
      |> Pages.parse()
      |> Test.Html.find("input##{@form_id}_date_started")
      |> Test.Html.attr("value")

    assert actual_date =~ ~r"\d\d\/\d\d\/\d\d\d\d"
    view
  end

  def assert_date_started(%View{} = view, date_string) do
    [actual_date] =
      view
      |> Pages.parse()
      |> Test.Html.find("input##{@form_id}_date_started")
      |> Test.Html.attr("value")

    assert actual_date == date_string
    view
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-start-interview")
    view_or_conn_or_html
  end

  def assert_person_interviewed_selections(%View{} = view, expected_selections) do
    assert Pages.actual_selections(view, "start-interview-form-person-interviewed", "radio") == expected_selections
    view
  end

  def assert_person_interviewed_sentinel_value(%View{} = view, expected_value) do
    [actual] =
      view
      |> Pages.parse()
      |> Test.Html.find("input##{@form_id}_person_interviewed___self__[type=radio]")
      |> Test.Html.attr("value")

    assert actual == expected_value

    view
  end

  def assert_proxy_selected(%View{} = view, expected_proxy_name) do
    assert %{"Proxy" => true} = Pages.actual_selections(view, "start-interview-form-person-interviewed", "radio")

    [actual_name] =
      view
      |> Pages.parse()
      |> Test.Html.find("input##{@form_id}_person_interviewed[type=text]")
      |> Test.Html.attr("value")

    assert actual_name == expected_proxy_name
    view
  end

  def assert_time_started(%View{} = view, :now) do
    {actual_time, actual_am_pm} = actual_time_started(view)

    assert actual_time =~ ~r"\d\d:\d\d"
    assert actual_am_pm in ~w{AM PM}
    view
  end

  def assert_time_started(%View{} = view, expected_time_string, expected_am_pm) do
    {actual_time, actual_am_pm} = actual_time_started(view)

    assert actual_time == expected_time_string
    assert actual_am_pm == expected_am_pm
    view
  end

  defp actual_time_started(view) do
    parsed = view |> Pages.parse()

    [actual_time] =
      parsed
      |> Test.Html.find("input##{@form_id}_time_started")
      |> Test.Html.attr("value")

    [actual_am_pm] =
      parsed
      |> Test.Html.find("select##{@form_id}_time_started_am_pm option[selected]")
      |> Enum.map(&Test.Html.text(&1))

    {actual_time, actual_am_pm}
  end

  def change_form(%View{} = view, attrs) do
    view |> element("#" <> @form_id) |> render_change(attrs)

    view
  end

  def datetime_started(%View{} = view) do
    state = view |> Pages.form_state()

    datestring = state["#{@form_id}[date_started]"]
    timestring = state["#{@form_id}[time_started]"]
    ampmstring = state["#{@form_id}[time_started_am_pm]"]

    Timex.parse!("#{datestring} #{timestring} #{ampmstring}", "{0M}/{0D}/{YYYY} {h12}:{m} {AM}")
  end
end
