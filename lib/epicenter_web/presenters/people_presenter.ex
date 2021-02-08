defmodule EpicenterWeb.Presenters.PeoplePresenter do
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias EpicenterWeb.Format
  alias EpicenterWeb.Unknown
  alias EpicenterWeb.Presenters.CaseInvestigationPresenter

  def archive_confirmation_message(selected_people),
    do: "Are you sure you want to archive #{map_size(selected_people)} person(s)?"

  def assigned_to_name(%Person{assigned_to: nil}),
    do: ""

  def assigned_to_name(%Person{assigned_to: assignee}),
    do: assignee.name

  def disabled?(selected_people),
    do: selected_people == %{}

  def exposure_date(person),
    do: person.contact_investigations |> hd() |> Map.get(:most_recent_date_together) |> Format.date()

  def external_id(person),
    do: Person.coalesce_demographics(person).external_id

  def full_name_and_external_ids(person) do
    person = person |> Cases.preload_demographics()

    full_name = person |> Person.coalesce_demographics() |> Format.person()

    external_ids =
      person
      |> Map.get(:demographics)
      |> Enum.map(& &1.external_id)
      |> Euclid.Extra.Enum.compact()
      |> Enum.map(&"##{&1}")

    [full_name | external_ids] |> Euclid.Extra.Enum.compact() |> Enum.join(", ")
  end

  def search_result_details(person) do
    person = person |> Cases.preload_demographics() |> Cases.preload_phones() |> Cases.preload_addresses()
    demographic = person |> Person.coalesce_demographics()

    Phoenix.HTML.Tag.content_tag :ul do
      [
        Phoenix.HTML.Tag.content_tag(:li, Format.date(demographic.dob)),
        Phoenix.HTML.Tag.content_tag(:li, Epicenter.Extra.String.capitalize(demographic.sex_at_birth)),
        Phoenix.HTML.Tag.content_tag(:li, Format.phone(person.phones)),
        Phoenix.HTML.Tag.content_tag(:li, Format.address(person.addresses))
      ]
    end
  end

  def full_name(person),
    do: person |> Person.coalesce_demographics() |> Format.person() |> Unknown.string_or_unknown()

  def is_archived?(person), do: person.archived_at != nil

  def is_editable?(person), do: !is_archived?(person)

  def latest_contact_investigation_status(person, current_date),
    do: person |> Person.latest_contact_investigation() |> CaseInvestigationPresenter.displayable_status(current_date)

  def selected?(selected_people, %Person{id: person_id}),
    do: Map.has_key?(selected_people, person_id)
end
