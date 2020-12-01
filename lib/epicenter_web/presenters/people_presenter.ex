defmodule EpicenterWeb.Presenters.PeoplePresenter do
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Person
  alias Epicenter.Extra
  alias EpicenterWeb.Format
  alias EpicenterWeb.Unknown

  def assigned_to_name(%Person{assigned_to: nil}),
    do: ""

  def assigned_to_name(%Person{assigned_to: assignee}),
    do: assignee.name

  def disabled?(selected_people),
    do: selected_people == %{}

  def exposure_date(person) do
    person.exposures |> hd() |> Map.get(:most_recent_date_together) |> Format.date()
  end

  def external_id(person),
    do: Person.coalesce_demographics(person).external_id

  def full_name(person) do
    demographic = Person.coalesce_demographics(person)
    [demographic.first_name, demographic.last_name] |> Euclid.Exists.filter() |> Enum.join(" ") |> Unknown.string_or_unknown()
  end

  def latest_case_investigation_status(person, current_date),
    do: person |> Person.latest_case_investigation() |> displayable_status(current_date)

  def latest_result(person) do
    lab_result = Person.latest_lab_result(person)

    if lab_result do
      result = lab_result.result || "unknown"

      "#{result}, #{days_ago(lab_result)}"
    else
      ""
    end
  end

  def selected?(selected_people, %Person{id: person_id}),
    do: Map.has_key?(selected_people, person_id)

  # # # Private

  defp days_ago(%{sampled_on: nil} = _lab_result), do: "unknown date"
  defp days_ago(%{sampled_on: sampled_on} = _lab_result), do: sampled_on |> Extra.Date.days_ago_string()

  defp displayable_status(nil, _),
    do: ""

  defp displayable_status(case_investigation, current_date) do
    case CaseInvestigation.status(case_investigation) do
      :pending ->
        "Pending interview"

      :started ->
        "Ongoing interview"

      :completed_interview ->
        case CaseInvestigation.isolation_monitoring_status(case_investigation) do
          :pending ->
            "Pending monitoring"

          :ongoing ->
            diff = Date.diff(case_investigation.isolation_monitoring_ended_on, current_date)
            "Ongoing monitoring (#{diff} days remaining)"

          :concluded ->
            "Concluded monitoring"
        end

      :discontinued ->
        "Discontinued"
    end
  end
end
