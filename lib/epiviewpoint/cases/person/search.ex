defmodule EpiViewpoint.Cases.Person.Search do
  import Ecto.Query

  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.Cases.Demographic
  alias EpiViewpoint.Repo

  def find(search_string) do
    case is_uuid?(search_string) do
      true ->
        find_matching_people(:person_id, [search_string], downcase: false)

      false ->
        search_tokens = search_string |> String.split(" ") |> Enum.map(&String.trim/1) |> Enum.map(&String.downcase/1)

        [{:external_id, false}, {:first_name, true}, {:last_name, true}]
        |> Enum.reduce(MapSet.new(), fn {field, string_field?}, results ->
          find_matching_people(field, search_tokens, downcase: string_field?)
          |> Cases.preload_demographics()
          |> Enum.filter(&coalesced_field_matches?(&1, field, search_tokens, string_field?))
          |> MapSet.new()
          |> MapSet.union(results)
        end)
        |> Enum.sort_by(&full_name/1)
    end
  end

  def coalesced_field_matches?(person, field, search_tokens, true = _string_field?),
    do: (person |> Person.coalesce_demographics() |> Map.get(field) |> String.downcase()) in search_tokens

  def coalesced_field_matches?(_person, _field, _search_tokens, false = _string_field?),
    do: true

  def full_name(person) do
    demographic = person |> Person.coalesce_demographics()
    [demographic.first_name, demographic.last_name] |> Enum.join(" ")
  end

  defp is_uuid?(term) do
    String.match?(term, ~r/[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/)
  end

  def find_matching_people(field, search_tokens, opts \\ []) do
    downcase? = Keyword.get(opts, :downcase, true)

    query =
      from demographic in Demographic,
        select: demographic.person_id,
        distinct: true

    query =
      if downcase?,
        do: query |> where([d], fragment("lower(?)", field(d, ^field)) in ^search_tokens),
        else: query |> where([d], field(d, ^field) in ^search_tokens)

    query
    |> Repo.all()
    |> Person.Query.get_people()
    |> Person.Query.reject_archived_people(true)
    |> Repo.all()
  end
end
