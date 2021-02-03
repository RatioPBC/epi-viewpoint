defmodule Epicenter.Extra.Enum do
  def at!(enum, index) do
    if length(enum) < index + 1 do
      raise "Out of range: index #{index} of enum with length #{length(enum)}: #{inspect(enum)}"
    else
      Enum.at(enum, index)
    end
  end

  def fetch_multiple(enum, indices) do
    for index <- indices do
      Enum.fetch!(enum, index)
    end
  end

  def find_indices(enum, values) do
    for value <- values do
      Enum.find_index(enum, &(value == &1))
    end
  end

  def intersect?(a, b),
    do: MapSet.intersection(MapSet.new(a || []), MapSet.new(b || [])) |> MapSet.size() > 0

  def reject_blank(enum),
    do: Enum.reject(enum, &Euclid.Exists.blank?/1)

  def sort_uniq(enum),
    do: enum |> Enum.sort() |> Enum.uniq()

  def sort_uniq(enum, sort_fun),
    do: enum |> Enum.sort(sort_fun) |> Enum.uniq()
end
