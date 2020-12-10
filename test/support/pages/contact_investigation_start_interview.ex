defmodule EpicenterWeb.Test.Pages.ContactInvestigationStartInterview do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.Exposure
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  @form_id "contact-investigation-interview-start-form"

  def visit(%Plug.Conn{} = conn, %Exposure{id: exposure_id}) do
    conn |> Pages.visit("/contact-investigations/#{exposure_id}/start-interview")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html
    |> Pages.assert_on_page("contact-investigation-start-interview")

    view_or_conn_or_html
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

  def change_form(%View{} = view, params) do
    view |> form("[data-role=start-interview-form]", params) |> render_change()
    view
  end
end
