defmodule EpicenterWeb.Presenters.CaseInvestigationPresenter do
  import Phoenix.LiveView.Helpers
  import Phoenix.HTML.Tag

  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Exposure
  alias Epicenter.Cases.Person
  alias EpicenterWeb.Format
  alias EpicenterWeb.PresentationConstants
  alias EpicenterWeb.Router.Helpers, as: Routes

  @symptoms_map %{
    "abdominal_pain" => "Abdominal pain",
    "chills" => "Chills",
    "cough" => "Cough",
    "diarrhea_gi" => "Diarrhea/GI",
    "fatigue" => "Fatigue",
    "fever" => "Fever > 100.4F",
    "headache" => "Headache",
    "loss_of_sense_of_smell" => "Loss of sense of smell",
    "loss_of_sense_of_taste" => "Loss of sense of taste",
    "muscle_ache" => "Muscle ache",
    "nasal_congestion" => "Nasal congestion",
    "shortness_of_breath" => "Shortness of breath",
    "sore_throat" => "Sore throat",
    "subjective_fever" => "Subjective fever (felt feverish)",
    "vomiting" => "Vomiting"
  }

  def contact_details_as_list(%Exposure{} = exposure) do
    content_tag :ul do
      build_details_list(exposure) |> Enum.map(&content_tag(:li, &1))
    end
  end

  def displayable_isolation_monitoring_status(case_investigation, current_date) do
    case CaseInvestigation.isolation_monitoring_status(case_investigation) do
      :pending ->
        styled_status("Pending", :pending, :isolation_monitoring)

      :ongoing ->
        diff = Date.diff(case_investigation.isolation_monitoring_end_date, current_date)
        styled_status("Ongoing", :ongoing, :isolation_monitoring, "(#{diff} days remaining)")

      :concluded ->
        styled_status("Concluded", :concluded, :isolation_monitoring)
    end
  end

  def displayable_interview_status(case_investigation)

  def displayable_interview_status(%{discontinued_at: nil} = case_investigation) do
    case CaseInvestigation.status(case_investigation) do
      :pending -> styled_status("Pending", :pending, :interview)
      :started -> styled_status("Ongoing", :started, :interview)
      :completed_interview -> styled_status("Completed", "completed-interview", :interview)
    end
  end

  def displayable_interview_status(_),
    do: [content_tag(:span, "Discontinued", class: :discontinued)]

  def displayable_clinical_status(%{clinical_status: nil}), do: "None"

  def displayable_clinical_status(%{clinical_status: clinical_status}),
    do: Gettext.gettext(Epicenter.Gettext, clinical_status)

  def displayable_symptoms(%{symptoms: nil}),
    do: "None"

  def displayable_symptoms(%{symptoms: []}),
    do: "None"

  def displayable_symptoms(%{symptoms: symptoms}),
    do: Enum.map(symptoms, &Map.get(@symptoms_map(), &1, &1)) |> Enum.join(", ")

  def history_items(case_investigation) do
    items = []

    items =
      if case_investigation.started_at do
        [
          %{
            text: "Started interview with #{with_interviewee_name(case_investigation)} on #{interview_start_date(case_investigation)}",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.case_investigation_start_interview_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationStartInterviewLive,
                    case_investigation
                  ),
                class: "case-investigation-link"
              )
          }
          | items
        ]
      else
        items
      end

    items =
      if case_investigation.discontinue_reason != nil do
        [
          %{
            text:
              "Discontinued interview on #{case_investigation.discontinued_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()}: #{
                case_investigation.discontinue_reason
              }",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.case_investigation_discontinue_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationDiscontinueLive,
                    case_investigation
                  ),
                id: "edit-discontinue-case-investigation-link-001",
                class: "discontinue-case-investigation-link"
              )
          }
          | items
        ]
      else
        items
      end

    items =
      if case_investigation.completed_interview_at != nil do
        [
          %{
            text: "Completed interview on #{completed_interview_date(case_investigation)}",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.case_investigation_complete_interview_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationCompleteInterviewLive,
                    case_investigation
                  ),
                id: "edit-complete-interview-link-001",
                class: "edit-complete-interview-link"
              )
          }
          | items
        ]
      else
        items
      end

    items |> Enum.reverse()
  end

  def interview_buttons(case_investigation) do
    case CaseInvestigation.status(case_investigation) do
      :pending ->
        [
          redirect_to(case_investigation, :start_interview),
          redirect_to(case_investigation, :discontinue_interview)
        ]

      :started ->
        [
          redirect_to(case_investigation, :complete_interview),
          redirect_to(case_investigation, :discontinue_interview)
        ]

      :completed_interview ->
        []

      :discontinued ->
        []
    end
  end

  def isolation_monitoring_button(case_investigation) do
    case CaseInvestigation.isolation_monitoring_status(case_investigation) do
      :pending ->
        live_redirect("Add isolation dates",
          to:
            Routes.case_investigation_isolation_monitoring_path(
              EpicenterWeb.Endpoint,
              EpicenterWeb.CaseInvestigationIsolationMonitoringLive,
              case_investigation
            ),
          id: "add-isolation-dates-case-investigation-link-001",
          class: "add-isolation-dates-case-investigation-link"
        )

      :ongoing ->
        live_redirect("Conclude isolation",
          to:
            Routes.case_investigation_conclude_isolation_monitoring_path(
              EpicenterWeb.Endpoint,
              EpicenterWeb.CaseInvestigationConcludeIsolationMonitoringLive,
              case_investigation
            ),
          id: "conclude-isolation-monitoring-case-investigation-link-001",
          class: "conclude-isolation-monitoring-case-investigation-link"
        )

      :concluded ->
        nil
    end
  end

  def isolation_monitoring_history_items(case_investigation) do
    items = []

    items =
      if case_investigation.isolation_monitoring_start_date do
        [
          %{
            text:
              "Isolation dates: #{Format.date(case_investigation.isolation_monitoring_start_date)} - #{
                Format.date(case_investigation.isolation_monitoring_end_date)
              }",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.case_investigation_isolation_monitoring_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationIsolationMonitoringLive,
                    case_investigation
                  ),
                id: "edit-isolation-monitoring-link-001",
                class: "case-investigation-link"
              )
          }
          | items
        ]
      else
        items
      end

    items =
      if case_investigation.isolation_concluded_at do
        [
          %{
            text:
              "Concluded isolation monitoring on #{concluded_isolation_monitoring_date(case_investigation)}. #{
                Gettext.gettext(Epicenter.Gettext, case_investigation.isolation_conclusion_reason)
              }",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.case_investigation_conclude_isolation_monitoring_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationConcludeIsolationMonitoringLive,
                    case_investigation
                  ),
                id: "edit-isolation-monitoring-conclusion-link-001",
                class: "case-investigation-link"
              )
          }
          | items
        ]
      else
        items
      end

    items |> Enum.reverse()
  end

  def symptoms_options() do
    [
      {"Fever > 100.4F", "fever"},
      {"Subjective fever (felt feverish)", "subjective_fever"},
      {"Cough", "cough"},
      {"Shortness of breath", "shortness_of_breath"},
      {"Diarrhea/GI", "diarrhea_gi"},
      {"Headache", "headache"},
      {"Muscle ache", "muscle_ache"},
      {"Chills", "chills"},
      {"Sore throat", "sore_throat"},
      {"Vomiting", "vomiting"},
      {"Abdominal pain", "abdominal_pain"},
      {"Nasal congestion", "nasal_congestion"},
      {"Loss of sense of smell", "loss_of_sense_of_smell"},
      {"Loss of sense of taste", "loss_of_sense_of_taste"},
      {"Fatigue", "fatigue"},
      {"Other", "Other"}
    ]
  end

  # # #

  defp build_details_list(%{
         guardian_name: guardian_name,
         guardian_phone: guardian_phone,
         relationship_to_case: relationship_to_case,
         most_recent_date_together: most_recent_date_together,
         household_member: household_member,
         under_18: under_18,
         exposed_person: exposed_person
       }) do
    demographic = Person.coalesce_demographics(exposed_person)
    phone = List.first(exposed_person.phones)

    details = [relationship_to_case]
    details = if household_member, do: details ++ ["Household"], else: details

    details =
      if under_18 do
        details = details ++ ["Minor"]
        details = details ++ ["Guardian: #{guardian_name}"]
        details = if Euclid.Exists.present?(guardian_phone), do: details ++ [Format.phone(guardian_phone)], else: details
        details
      else
        if Euclid.Exists.present?(phone), do: details ++ [Format.phone(phone)], else: details
      end

    details = if Euclid.Exists.present?(demographic.preferred_language), do: details ++ [demographic.preferred_language], else: details
    details ++ ["Last together #{Format.date(most_recent_date_together)}"]
  end

  defp completed_interview_date(case_investigation),
    do: case_investigation.completed_interview_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()

  defp concluded_isolation_monitoring_date(case_investigation),
    do: case_investigation.isolation_concluded_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()

  defp convert_to_presented_time_zone(datetime),
    do: DateTime.shift_zone!(datetime, PresentationConstants.presented_time_zone())

  defp interview_start_date(case_investigation),
    do: case_investigation.started_at |> convert_to_presented_time_zone() |> Format.date_time_with_zone()

  defp redirect_to(case_investigation, :complete_interview) do
    live_redirect("Complete interview",
      to:
        Routes.case_investigation_complete_interview_path(
          EpicenterWeb.Endpoint,
          EpicenterWeb.CaseInvestigationCompleteInterviewLive,
          case_investigation
        ),
      id: "complete-interview-case-investigation-link-001",
      class: "complete-interview-case-investigation-link"
    )
  end

  defp redirect_to(case_investigation, :start_interview) do
    live_redirect("Start interview",
      to: Routes.case_investigation_start_interview_path(EpicenterWeb.Endpoint, EpicenterWeb.CaseInvestigationStartInterviewLive, case_investigation),
      id: "start-interview-case-investigation-link-001",
      class: "start-interview-case-investigation-link"
    )
  end

  defp redirect_to(case_investigation, :discontinue_interview) do
    live_redirect("Discontinue",
      to: Routes.case_investigation_discontinue_path(EpicenterWeb.Endpoint, EpicenterWeb.CaseInvestigationDiscontinueLive, case_investigation),
      id: "discontinue-case-investigation-link-001",
      class: "discontinue-case-investigation-link"
    )
  end

  defp styled_status(displayable_status, status, type, postscript \\ "") when type in [:interview, :isolation_monitoring] do
    type_string = %{interview: "interview", isolation_monitoring: "isolation monitoring"}[type]

    content_tag :span do
      [content_tag(:span, displayable_status, class: status), " #{type_string} #{postscript}"]
    end
  end

  defp with_interviewee_name(%CaseInvestigation{interview_proxy_name: nil} = case_investigation),
    do: case_investigation |> Cases.preload_person() |> Map.get(:person) |> Cases.preload_demographics() |> Format.person()

  defp with_interviewee_name(%CaseInvestigation{interview_proxy_name: interview_proxy_name}),
    do: "proxy #{interview_proxy_name}"
end
