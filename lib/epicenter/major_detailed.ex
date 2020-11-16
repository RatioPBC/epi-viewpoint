defmodule Epicenter.MajorDetailed do
  def combine(map, prefix) do
    prefix = Euclid.Extra.Atom.to_string(prefix)
    map = map |> Euclid.Extra.Map.stringify_keys()
    keys = map |> Map.keys() |> Enum.filter(&String.starts_with?(&1, prefix))

    Enum.reduce(keys, %{}, fn key, result ->
      value = Map.get(map, key)

      cond do
        key == prefix ->
          value |> List.wrap() |> Enum.reduce(result, fn new_key, acc -> put_or_concat_map_value(acc, new_key, nil) end)

        key == prefix <> "_other" ->
          new_key = value
          put_or_concat_map_value(result, new_key, nil)

        key =~ ~r/^#{prefix}_(.*)_other$/ ->
          [_, new_key] = Regex.run(~r/^#{prefix}_(.*)_other$/, key)
          put_or_concat_map_value(result, new_key, value)

        key =~ ~r/^#{prefix}_(.*)$/ ->
          [_, new_key] = Regex.run(~r/^#{prefix}_(.*)$/, key)
          put_or_concat_map_value(result, new_key, value)
      end
    end)
  end

  def split(map, prefix, standard_values) do
    map = Map.get(map, prefix) || %{}

    Enum.reduce(map, %{}, fn
      {key, nil}, result ->
        if standard_value?(key, standard_values),
          do: put_or_concat_map_value(result, prefix, key),
          else: put_or_concat_map_value(result, :"#{prefix}_other", key)

      {key, value_or_values}, result ->
        Enum.reduce(List.wrap(value_or_values), result, fn value, acc ->
          if standard_value?(value, standard_values),
            do: acc |> put_or_concat_map_value(prefix, key) |> put_or_concat_map_value(:"#{prefix}_#{key}", value),
            else: put_or_concat_map_value(acc, :"#{prefix}_#{key}_other", value)
        end)
    end)
  end

  defp standard_value?(value, standard_values) do
    Enum.any?(standard_values, fn {_display, standard_value, _parent} -> value == standard_value end)
  end

  defp put_or_concat_map_value(map, key, new_value) do
    if Map.get(map, key) == nil,
      do: Map.put(map, key, new_value),
      else: Map.update(map, key, [], fn existing -> sorted_list_concat(new_value, existing) end)
  end

  defp sorted_list_concat(a, b) do
    (List.wrap(a) ++ List.wrap(b)) |> Enum.sort() |> Enum.uniq()
  end
end
