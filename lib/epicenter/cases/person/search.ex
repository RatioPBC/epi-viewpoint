defmodule Epicenter.Cases.Person.Search do
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Person.Search.Query
  alias Epicenter.Cases.Demographic
  alias Epicenter.Repo

  def find(search_string) do
    case is_uuid?(search_string) do
      true ->
        Query.uuid_matches(search_string) |> Repo.all() |> Person.Query.get_people() |> Repo.all()

      false ->
        external_id_matches = Query.external_id_matches(search_string) |> Repo.all() |> Person.Query.get_people() |> Repo.all()

        search_terms = search_string |> String.split(" ") |> Enum.map(&String.trim/1)

        first_name_matches =
          Query.first_name_matches(search_terms)
          |> Repo.all()
          |> Enum.uniq()
          |> Person.Query.get_people()
          |> Repo.all()
          |> Cases.preload_demographics()
          |> Enum.filter(&coalesced_field_matches?(&1, :first_name, search_terms))

        last_name_matches =
          Query.last_name_matches(search_terms)
          |> Repo.all()
          |> Enum.uniq()
          |> Person.Query.get_people()
          |> Repo.all()
          |> Cases.preload_demographics()
          |> Enum.filter(&coalesced_field_matches?(&1, :last_name, search_terms))

        external_id_matches ++ first_name_matches ++ last_name_matches
    end
  end

  def coalesced_field_matches?(person, field, search_terms) do
    demographic = person |> Person.coalesce_demographics()
    search_terms |> Enum.member?(demographic[field])
  end

  defp is_uuid?(term) do
    String.match?(term, ~r/[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/)
  end

  defmodule Query do
    import Ecto.Query

    def uuid_matches(term) do
      from person in Person,
        join: demographic in Demographic,
        on: person.id == demographic.person_id,
        where: person.id == ^term,
        select: person.id,
        distinct: true
    end

    def external_id_matches(term) do
      from person in Person,
        join: demographic in Demographic,
        on: person.id == demographic.person_id,
        where: demographic.external_id == ^term,
        select: person.id,
        distinct: true
    end

    def first_name_matches(search_terms) do
      from person in Person,
        join: demographic in Demographic,
        on: person.id == demographic.person_id,
        where: demographic.first_name in ^search_terms,
        select: person.id,
        distinct: true
    end

    def last_name_matches(search_terms) do
      from person in Person,
        join: demographic in Demographic,
        on: person.id == demographic.person_id,
        where: demographic.last_name in ^search_terms,
        select: person.id,
        distinct: true
    end
  end
end
