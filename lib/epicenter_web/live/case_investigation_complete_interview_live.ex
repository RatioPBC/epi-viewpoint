defmodule EpicenterWeb.CaseInvestigationCompleteInterviewLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.CompleteInterviewForm
  alias EpicenterWeb.PresentationConstants
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, ok: 1]

  def mount(%{"id" => case_investigation_id}, session, socket) do
    case_investigation = case_investigation_id |> Cases.get_case_investigation()

    socket
    |> authenticate_user(session)
    |> assign_page_title("Complete interview")
    |> assign(:form_changeset, CompleteInterviewForm.changeset(case_investigation))
    |> ok()
  end

  def complete_interview_form_builder(form) do
    timezone = Timex.timezone(PresentationConstants.presented_time_zone(), Timex.now())

    Form.new(form)
    |> Form.line(&Form.date_field(&1, :date_completed, "Date interview completed"))
    |> Form.line(fn line ->
      line
      |> Form.text_field(:time_completed, "Time interview completed")
      |> Form.select(:time_completed_am_pm, "", time_completed_am_pm_options(), span: 1)
      |> Form.content_div(timezone.abbreviation, row: 3)
    end)
    |> Form.safe()
  end

  defp time_completed_am_pm_options(),
    do: ["AM", "PM"]
end
