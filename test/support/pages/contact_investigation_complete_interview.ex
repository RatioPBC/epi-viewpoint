defmodule EpicenterWeb.Test.Pages.ContactInvestigationCompleteInterview do
  import Phoenix.LiveViewTest
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions

  alias Epicenter.Cases.ContactInvestigation
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  @form_id "contact-investigation-complete-interview-form"

  def visit(%Plug.Conn{} = conn, %ContactInvestigation{id: id}) do
    conn |> Pages.visit("/contact-investigations/#{id}/complete-interview")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("contact-investigation-complete-interview")
  end

  def assert_header(view, header_text) do
    view |> render() |> Test.Html.parse() |> Test.Html.role_text("complete-interview-title") |> assert_eq(header_text)
    view
  end

  def assert_date_completed(view, date_string) do
    [actual_date] =
      view
      |> Pages.parse()
      |> Test.Html.find("input##{@form_id}_date_completed")
      |> Test.Html.attr("value")

    assert actual_date == date_string
    view
  end

  def assert_time_completed(view, expected_time_string, expected_am_pm) do
    assert actual_time_completed(view) == {expected_time_string, expected_am_pm}
    view
  end

  defp actual_time_completed(view) do
    parsed = view |> Pages.parse()

    [actual_time] =
      parsed
      |> Test.Html.find("input##{@form_id}_time_completed")
      |> Test.Html.attr("value")

    [actual_am_pm] =
      parsed
      |> Test.Html.find("select##{@form_id}_time_completed_am_pm option[selected]")
      |> Enum.map(&Test.Html.text(&1))

    {actual_time, actual_am_pm}
  end
end
