defmodule EpicenterWeb.Presenters.PeoplePresenter do
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Person
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias EpicenterWeb.Format
  alias EpicenterWeb.Unknown

  def assigned_to_name(%Person{assigned_to: nil}),
    do: ""

  def assigned_to_name(%Person{assigned_to: assignee}),
    do: assignee.name

  def disabled?(selected_people),
    do: selected_people == %{}

  def exposure_date(person) do
    person.contact_investigations |> hd() |> Map.get(:most_recent_date_together) |> Format.date()
  end

  def external_id(person),
    do: Person.coalesce_demographics(person).external_id

  def full_name(person) do
    demographic = Person.coalesce_demographics(person)
    [demographic.first_name, demographic.last_name] |> Euclid.Exists.filter() |> Enum.join(" ") |> Unknown.string_or_unknown()
  end

  def latest_case_investigation_status(person, current_date),
    do: person |> Person.latest_case_investigation() |> displayable_status(current_date)

  def latest_contact_investigation_status(person, current_date),
    do: person |> Person.latest_contact_investigation() |> displayable_status(current_date)

  def selected?(selected_people, %Person{id: person_id}),
    do: Map.has_key?(selected_people, person_id)

  # # # Private

  defp displayable_status(nil, _),
    do: ""

  defp displayable_status(%CaseInvestigation{} = investigation, current_date) do
    displayable_status(
      investigation.interview_status,
      investigation.isolation_monitoring_status,
      investigation.isolation_monitoring_ends_on,
      current_date
    )
  end

  defp displayable_status(%ContactInvestigation{} = investigation, current_date) do
    displayable_status(
      investigation.interview_status,
      investigation.quarantine_monitoring_status,
      investigation.quarantine_monitoring_ends_on,
      current_date
    )
  end

  defp displayable_status(interview_status, monitoring_status, monitoring_ends_on, current_date) do
    case interview_status do
      "pending" ->
        "Pending interview"

      "started" ->
        "Ongoing interview"

      "completed" ->
        case monitoring_status do
          "pending" ->
            "Pending monitoring"

          "ongoing" ->
            diff = Date.diff(monitoring_ends_on, current_date)
            "Ongoing monitoring (#{diff} days remaining)"

          "concluded" ->
            "Concluded monitoring"
        end

      "discontinued" ->
        "Discontinued"
    end
  end
end
