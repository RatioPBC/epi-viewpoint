defmodule Epicenter.Cases.Person.Duplicates do
  alias Epicenter.Cases.Person

  defmodule Query do
    import Ecto.Query

    @duplicates_sql """
    select distinct(potential_duplicate_person_id) from (
        with latest_last_name as (
            select max(seq) max_seq, person_id
            from demographics
            where last_name is not null
            group by person_id
        ),
        latest_first_name as (
            select max(seq) max_seq, person_id
            from demographics
            where first_name is not null
            group by person_id
        ),
        latest_dob as (
            select max(seq) max_seq, person_id
            from demographics
            where dob is not null
            group by person_id
        )
        select d.person_id as potential_duplicate_person_id
        from demographics d
        join latest_last_name latest on d.seq = latest.max_seq and d.person_id = latest.person_id
        and lower(d.last_name) = lower($1)
        where d.person_id != $4
        INTERSECT
        (
            select d.person_id
            from demographics d
            join latest_first_name latest
            on d.seq = latest.max_seq and d.person_id = latest.person_id
            where lower(d.first_name) = lower($2)
            UNION
            select d.person_id
            from demographics d
            join latest_dob latest
            on d.seq = latest.max_seq and d.person_id = latest.person_id
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
            where source.tid = 'source'
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

      from people in Person,
        where: people.id in ^person_ids
    end
  end
end
