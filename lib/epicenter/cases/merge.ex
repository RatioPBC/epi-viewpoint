defmodule Epicenter.Cases.Merge do
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Extra

  def merge_conflicts(person_ids, user, field_names) when is_list(field_names) do
    people =
      Cases.get_people(person_ids, user)
      |> Cases.preload_demographics()
      |> Enum.map(&Person.coalesce_demographics/1)

    Enum.reduce(field_names, %{}, fn field_name, all_conflicts ->
      field_values = people |> Euclid.Extra.Enum.pluck(field_name) |> Extra.Enum.sort_uniq(&Extra.String.case_insensitive_sort_fun/2)
      all_conflicts |> Map.put(field_name, field_values)
    end)
  end
end
