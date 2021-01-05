defmodule EpicenterWeb.Test.Pages.ContactInvestigationStartInterview do
  import Phoenix.LiveViewTest

  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %ContactInvestigation{id: id}) do
    conn |> Pages.visit("/contact-investigations/#{id}/start-interview")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html
    |> Pages.assert_on_page("contact-investigation-start-interview")

    view_or_conn_or_html
  end

  def date_started(view) do
    Pages.form_state(view)["start_interview_form[date_started]"]
  end

  def time_started(view) do
    %{
      "start_interview_form[time_started]" => actual_time,
      "start_interview_form[time_started_am_pm]" => actual_am_pm
    } = Pages.form_state(view)

    actual_time <> actual_am_pm
  end

  def change_form(%View{} = view, params) do
    view |> form("[data-role=start-interview-form]", params) |> render_change()
    view
  end

  def go_back(%View{} = view) do
    view |> element("[data-role=back-link]") |> render_click()
  end

  def form_title(%View{} = view) do
    view
    |> render()
    |> Pages.parse()
    |> Test.Html.find!("[data-role=form-title]")
    |> Test.Html.text()
  end
end
