defmodule EpicenterWeb.Profile.CaseInvestigationPresenter do
  import Phoenix.LiveView.Helpers
  import Phoenix.HTML.Tag

  alias Epicenter.Cases
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Exposure
  alias Epicenter.Cases.Person
  alias Epicenter.Format
  alias EpicenterWeb.PresentationConstants
  alias EpicenterWeb.Router.Helpers, as: Routes

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

      :discontinued ->
        []
    end
  end

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

    items |> Enum.reverse()
  end

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

  defp with_interviewee_name(%CaseInvestigation{interview_proxy_name: nil} = case_investigation),
    do: case_investigation |> Cases.preload_person() |> Map.get(:person) |> Cases.preload_demographics() |> Format.person()

  defp with_interviewee_name(%CaseInvestigation{interview_proxy_name: interview_proxy_name}),
    do: "proxy #{interview_proxy_name}"

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

  @symptom_map %{
    "fever" => "Fever > 100.4F",
    "subjective_fever" => "Subjective fever (felt feverish)",
    "cough" => "Cough",
    "shortness_of_breath" => "Shortness of breath",
    "diarrhea_gi" => "Diarrhea/GI",
    "headache" => "Headache",
    "muscle_ache" => "Muscle ache",
    "chills" => "Chills",
    "sore_throat" => "Sore throat",
    "vomiting" => "Vomiting",
    "abdominal_pain" => "Abdominal pain",
    "nasal_congestion" => "Nasal congestion",
    "loss_of_sense_of_smell" => "Loss of sense of smell",
    "loss_of_sense_of_taste" => "Loss of sense of taste",
    "fatigue" => "Fatigue"
  }

  def symptom_map() do
    @symptom_map
  end

  def displayable_case_investigation_status(case_investigation)

  def displayable_case_investigation_status(%{discontinued_at: nil} = case_investigation) do
    case CaseInvestigation.status(case_investigation) do
      :pending -> styled_status("Pending", :pending)
      :started -> styled_status("Ongoing", :started)
    end
  end

  def displayable_case_investigation_status(_), do: [content_tag(:span, "Discontinued", class: :discontinued)]

  def clinical_statuses_options() do
    [
      {"Unknown", "unknown"},
      {"Symptomatic", "symptomatic"},
      {"Asymptomatic", "asymptomatic"}
    ]
  end

  @clinical_status_map %{
    nil => "None",
    "unknown" => "Unknown",
    "symptomatic" => "Symptomatic",
    "asymptomatic" => "Asymptomatic"
  }

  def displayable_clinical_status(%{clinical_status: clinical_status}) do
    Map.get(@clinical_status_map, clinical_status)
  end

  def displayable_symptom_onset_date(%{symptom_onset_date: nil}), do: "None"
  def displayable_symptom_onset_date(%{symptom_onset_date: symptom_onset_date}), do: Format.date(symptom_onset_date)

  def displayable_symptoms(%{symptoms: nil}), do: "None"
  def displayable_symptoms(%{symptoms: []}), do: "None"

  def displayable_symptoms(%{symptoms: symptoms}) do
    Enum.map(symptoms, fn symptom_code ->
      Map.get(symptom_map(), symptom_code, symptom_code)
    end)
    |> Enum.join(", ")
  end

  defp styled_status(displayable_status, status) do
    content_tag :span do
      [content_tag(:span, displayable_status, class: status), " interview"]
    end
  end

  def contact_details_as_list(%Exposure{} = exposure) do
    content_tag :ul do
      build_details_list(exposure) |> Enum.map(&content_tag(:li, &1))
    end
  end

  defp build_details_list(%{
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
    details = if under_18, do: details ++ ["Minor"], else: details
    details = if Euclid.Exists.present?(phone), do: details ++ [Format.phone(phone)], else: details
    details = if Euclid.Exists.present?(demographic.preferred_language), do: details ++ [demographic.preferred_language], else: details
    details ++ ["Last together #{Format.date(most_recent_date_together)}"]
  end
end
