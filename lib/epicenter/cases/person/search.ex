defmodule Epicenter.Cases.Person.Search do
  import Ecto.Query

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Demographic
  alias Epicenter.Repo

  def find(search_string, user) do
    case is_uuid?(search_string) do
      true ->
        Cases.get_person(search_string, user) |> List.wrap()

      false ->
        search_tokens = search_string |> String.split(" ") |> Enum.map(&String.trim/1) |> Enum.map(&String.downcase/1)

        external_id_matches = find_matches(:external_id, search_tokens)

        first_name_matches =
          find_matches(:first_name, search_tokens)
          |> Cases.preload_demographics()
          |> Enum.filter(&coalesced_field_matches?(&1, :first_name, search_tokens))

        last_name_matches =
          find_matches(:last_name, search_tokens)
          |> Cases.preload_demographics()
          |> Enum.filter(&coalesced_field_matches?(&1, :last_name, search_tokens))

        (external_id_matches ++ first_name_matches ++ last_name_matches)
        |> Enum.uniq()
        |> AuditLog.view(user)
    end
  end

  def coalesced_field_matches?(person, field, search_tokens) do
    demographic = person |> Person.coalesce_demographics()
    search_tokens |> Enum.member?(String.downcase(demographic[field]))
  end

  defp is_uuid?(term) do
    String.match?(term, ~r/[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/)
  end

  def find_matches(field, search_tokens) do
    query =
      from demographic in Demographic,
        select: demographic.person_id,
        distinct: true

    query
    |> where([d], fragment("lower(?)", field(d, ^field)) in ^search_tokens)
    |> Repo.all()
    |> Person.Query.get_people()
    |> Repo.all()
  end
end
