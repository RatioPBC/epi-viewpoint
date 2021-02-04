defmodule Epicenter.Cases.Person.Search do
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Person.Search.Query
  alias Epicenter.Cases.Demographic
  alias Epicenter.Repo

  def find(term) do
    case is_uuid?(term) do
      true ->
        Query.uuid_matches(term) |> Repo.all() |> Person.Query.get_people() |> Repo.all()

      false ->
        external_id_matches = Query.external_id_matches(term) |> Repo.all() |> Person.Query.get_people() |> Repo.all()

        first_name_matches =
          Query.first_name_matches(term)
          |> Repo.all()
          |> Enum.uniq()
          |> Person.Query.get_people()
          |> Repo.all()
          |> Cases.preload_demographics()
          |> Enum.filter(&coalesced_first_name_matches?(&1, term))

        external_id_matches ++ first_name_matches
    end
  end

  def coalesced_first_name_matches?(person, term) do
    demographic = person |> Person.coalesce_demographics()
    demographic.first_name == term
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

    def first_name_matches(term) do
      from person in Person,
        join: demographic in Demographic,
        on: person.id == demographic.person_id,
        where: demographic.first_name == ^term,
        select: person.id,
        distinct: true
    end
  end
end
