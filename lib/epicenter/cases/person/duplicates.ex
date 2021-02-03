defmodule Epicenter.Cases.Person.Duplicates do
  alias Epicenter.Cases
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Person.Duplicates.Query
  alias Epicenter.Extra

  def find(person, repo_fn),
    do: person |> Query.all() |> repo_fn.() |> preload() |> Enum.filter(&coalesced_match?(person, &1))

  def coalesced_match?(person1, person2) do
    person1 = person1 |> preload()
    person2 = person2 |> preload()

    demographics1 = person1 |> Person.coalesce_demographics()
    demographics2 = person2 |> Person.coalesce_demographics()

    last_names? = String.downcase(demographics1.last_name) == String.downcase(demographics2.last_name)
    first_names? = String.downcase(demographics1.first_name) == String.downcase(demographics2.first_name)
    dobs? = demographics1.dob == demographics2.dob
    phones? = Extra.Enum.intersect?(Euclid.Extra.Enum.pluck(person1.phones, :number), Euclid.Extra.Enum.pluck(person2.phones, :number))

    addresses? =
      Extra.Enum.intersect?(
        Enum.map(person1.addresses, &Address.to_comparable_string/1),
        Enum.map(person2.addresses, &Address.to_comparable_string/1)
      )

    last_names? && (first_names? || dobs? || phones? || addresses?)
  end

  defp preload(person_or_people_or_nil),
    do: person_or_people_or_nil |> Cases.preload_demographics() |> Cases.preload_phones() |> Cases.preload_addresses()

  defmodule Query do
    import Ecto.Query

    @duplicates_sql """
    select distinct(potential_duplicate_person_id) from (
        select d.person_id as potential_duplicate_person_id
        from demographics d
        where lower(d.last_name) = lower($1)
        and d.person_id != $4
        INTERSECT
        (
            select d.person_id
            from demographics d
            where lower(d.first_name) = lower($2)
            UNION
            select d.person_id
            from demographics d
            where d.dob = $3
            UNION
            select target.person_id
            from phones target
            join phones source on target.number = source.number
            where source.person_id = $4
            and source.person_id != target.person_id
            UNION
            select target.person_id
            from addresses target
            join addresses source on
                lower(target.street) = lower(source.street) and
                lower(target.city) = lower(source.city) and
                lower(target.state) = lower(source.state) and
                lower(target.postal_code) = lower(source.postal_code)
            where source.person_id = $4
            and target.person_id != source.person_id
        )
    ) as potential_duplicates
    """

    def all(person) do
      demographic = Person.coalesce_demographics(person)

      {:ok, person_uuid} = person.id |> Ecto.UUID.dump()

      %{rows: person_ids} =
        Ecto.Adapters.SQL.query!(
          Epicenter.Repo,
          @duplicates_sql,
          [demographic.last_name, demographic.first_name, demographic.dob, person_uuid]
        )

      person_ids =
        person_ids
        |> Enum.map(fn val ->
          {:ok, uuid} = Ecto.UUID.cast(hd(val))
          uuid
        end)

      from(people in Person, where: people.id in ^person_ids)
      |> Person.Query.reject_archived_people(true)
    end
  end
end
