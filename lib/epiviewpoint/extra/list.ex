defmodule EpiViewpoint.Extra.List do
  def concat(a, b),
    do: List.wrap(a) ++ List.wrap(b)

  def sorted_flat_compact(list),
    do: (list || []) |> List.flatten() |> Enum.filter(&Euclid.Exists.present?/1) |> Enum.sort()
end
