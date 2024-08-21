defmodule EpiViewpoint.Cases.Merge do
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Merge.SaveMerge
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.Extra

  @sort_funs %{string: &Extra.String.case_insensitive_sort_fun/2, date: Date}

  def fields_with_conflicts(merge_conflicts) do
    Enum.reduce(merge_conflicts, [], fn
      {k, v}, accumulated_fields when v != [] -> [k | accumulated_fields]
      _, accumulated_fields -> accumulated_fields
    end)
  end

  def has_merge_conflicts?(merge_conflicts) do
    Enum.any?(merge_conflicts, fn {_k, v} -> Euclid.Exists.present?(v) end)
  end

  def merge_conflicts(person_ids, user, field_names_and_types) when is_list(field_names_and_types) do
    people =
      Cases.get_people(person_ids, user)
      |> Cases.preload_demographics()
      |> Enum.map(&Person.coalesce_demographics/1)

    Enum.reduce(field_names_and_types, %{}, fn {field_name, field_type}, all_conflicts ->
      field_values = people |> Euclid.Extra.Enum.pluck(field_name) |> sort(@sort_funs[field_type])

      conflicts =
        case length(field_values) do
          0 -> []
          1 -> []
          _ -> field_values
        end

      all_conflicts |> Map.put(field_name, conflicts)
    end)
  end

  def merge(duplicate_person_ids, into: canonical_person_id, merge_conflict_resolutions: into_person_attrs, current_user: current_user) do
    SaveMerge.merge(duplicate_person_ids, into: canonical_person_id, merge_conflict_resolutions: into_person_attrs, current_user: current_user)
  end

  defp sort(values, sort_fun),
    do: values |> Euclid.Exists.filter() |> Enum.uniq() |> Enum.sort(sort_fun)
end
