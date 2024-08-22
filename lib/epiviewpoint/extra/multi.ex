defmodule EpiViewpoint.Extra.Multi do
  def get({:ok, map}, key) when is_map(map), do: {:ok, Map.get(map, key)}
  def get(tuple, _key) when is_tuple(tuple), do: tuple
end
