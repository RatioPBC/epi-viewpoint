defmodule Epicenter.Extra.Map do
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
end
