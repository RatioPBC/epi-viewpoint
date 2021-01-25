defmodule Epicenter.Cases.Merge do
  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Extra

  @sort_funs %{string: &Extra.String.case_insensitive_sort_fun/2, date: Date}

  def merge_conflicts(person_ids, user, field_names_and_types) when is_list(field_names_and_types) do
    people =
      Cases.get_people(person_ids, user)
      |> Cases.preload_demographics()
      |> Enum.map(&Person.coalesce_demographics/1)

    Enum.reduce(field_names_and_types, %{}, fn {field_name, field_type}, all_conflicts ->
      field_values = people |> Euclid.Extra.Enum.pluck(field_name) |> sort(@sort_funs[field_type])
      all_conflicts |> Map.put(field_name, field_values)
    end)
  end

  defp sort(values, sort_fun),
    do: values |> Euclid.Exists.filter() |> Enum.uniq() |> Enum.sort(sort_fun)
end
