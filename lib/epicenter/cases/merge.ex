defmodule Epicenter.Cases.Merge do
  alias Epicenter.Cases
  alias Epicenter.Cases.Person

  def merge_conflicts(person_ids, user) do
    people =
      Cases.get_people(person_ids, user)
      |> Cases.preload_demographics()
      |> Enum.map(&Person.coalesce_demographics/1)

    unique_first_names = people |> Enum.map(& &1.first_name) |> Enum.uniq()
    %{unique_first_names: unique_first_names}
  end
end
