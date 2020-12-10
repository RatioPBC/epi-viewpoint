defmodule Epicenter.Extra.Map do
  alias Epicenter.Extra

  @doc "Removes the item described by `keypath` from nested map `map` if it exists"
  def delete_in(map, keypath) do
    if Extra.Map.get_in(map, keypath) do
      {_existing_value, new_map} = pop_in(map, safe_keypath(keypath))
      new_map
    else
      map
    end
  end

  @doc "Returns the item described by `keypath` from nested map `map`, or `nil` if it does not exist"
  def get_in(map, [key] = _keypath) when is_map(map), do: Map.get(map, key)
  def get_in(map, [key | rest] = _keypath) when is_map(map), do: Map.get(map, key) |> Extra.Map.get_in(rest)
  def get_in(_not_map, _keypath), do: nil

  @doc """
  Puts `new_value` in nested map `map` at `keypath`, creating new nested maps along the way if necessary.
  If an item already exists at `keypath`, it will be replaced if `on_conflict` is `:replace`, or it
  will be appended if `on_conflict` is `:list_append` (potentially converting the existing value to a list).
  """
  def put_in(map, keypath, new_value, on_conflict: :replace) do
    {_existing_value, new_map} =
      get_and_update_in(map, safe_keypath(keypath), fn
        existing_value -> {existing_value, new_value}
      end)

    new_map
  end

  def put_in(map, keypath, new_value, on_conflict: :list_append) do
    {_existing_value, new_map} =
      get_and_update_in(map, safe_keypath(keypath), fn
        nil = _existing_value ->
          {nil, new_value}

        existing_value when is_list(existing_value) ->
          if new_value in existing_value,
            do: {existing_value, existing_value},
            else: {existing_value, Extra.List.concat(existing_value, new_value)}

        existing_value ->
          if existing_value == new_value,
            do: {existing_value, existing_value},
            else: {existing_value, [existing_value, new_value]}
      end)

    new_map
  end

  # # #

  def has_key?(map, key, :coerce_key_to_existing_atom) when is_atom(key),
    do: Map.has_key?(map, key)

  def has_key?(map, key, :coerce_key_to_existing_atom) when is_binary(key),
    do: Extra.String.is_existing_atom?(key) && Map.has_key?(map, String.to_existing_atom(key))

  @doc """
  Converts a map to a list that contains the keys and values of the map, by alphabetizing the keys
  and then traversing in depth-first order. Values can be scalars or lists.

    to_list(%{"z" => ["z1", "z2"], "a" => "a1"}, :depth_first)
    #=> ["a", "a1", "z", "z1", "z2"]
  """
  def to_list(map, :depth_first) do
    map
    |> Map.keys()
    |> Enum.sort(:desc)
    |> Enum.reduce([], fn key, acc -> [key | [Map.get(map, key) | acc]] end)
    |> List.flatten()
  end

  # # #

  defp safe_keypath(keypath), do: Enum.map(keypath, &Access.key(&1, %{}))
end
