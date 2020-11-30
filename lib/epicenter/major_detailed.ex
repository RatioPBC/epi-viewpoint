defmodule Epicenter.MajorDetailed do
  alias Epicenter.Extra

  def for_form(nil, standard_values),
    do: for_form(%{}, standard_values)

  def for_form(list, standard_values) when is_list(list),
    do: for_form(%{"major" => list}, standard_values)

  def for_form(struct, standard_values) when is_struct(struct),
    do: for_form(Map.from_struct(struct), standard_values)

  def for_form(map, standard_values) when is_map(map) do
    cleaned = map |> clean()

    case {Map.get(cleaned, "major", []), Map.get(cleaned, "detailed", [])} do
      {major, detailed} when is_binary(major) and is_list(detailed) ->
        %{
          "major" => [major] |> split_values_and_other(standard_values),
          "detailed" => %{major => detailed |> split_values_and_other(standard_values)}
        }

      {major, detailed} ->
        %{
          "major" => major |> List.wrap() |> split_values_and_other(standard_values),
          "detailed" => detailed |> Map.new(fn {k, v} -> {k, split_values_and_other(v, standard_values)} end)
        }
    end
  end

  def for_model(map, :map = _model_data_structure) do
    cleaned = map |> clean()

    %{
      "major" => cleaned |> Map.get("major", %{}) |> combine_values_and_other(),
      "detailed" => cleaned |> Map.get("detailed", %{}) |> Map.new(fn {k, v} -> {k, combine_values_and_other(v)} end)
    }
  end

  def for_model(map, :list = _model_data_structure) do
    cleaned = map |> clean()

    if !(Map.get(cleaned, "detailed") in [nil, %{}]),
      do: raise("Detailed values not allowed when converting to a list")

    cleaned |> Map.get("major", %{}) |> combine_values_and_other()
  end

  def for_display(map) do
    cleaned = map |> clean()

    major = Map.get(cleaned, "major", [])
    detailed = Map.get(cleaned, "detailed", %{}) |> Enum.reduce([], fn {_k, v}, acc -> [v | acc] end)

    Extra.List.sorted_flat_compact([major, detailed])
  end

  # # #

  def clean(nil),
    do: clean(%{})

  def clean(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      k = Euclid.Extra.Atom.to_string(k)
      v = if is_map(v), do: clean(v), else: v
      if Euclid.Exists.blank?(v), do: acc, else: Map.put(acc, k, v)
    end)
  end

  def combine_values_and_other(map) do
    sorted_list_concat(Map.get(map, "values", []), Map.get(map, "other", []))
  end

  def split_values_and_other(list, standard_values) do
    {values, other} = Enum.split_with(list, &Enum.member?(standard_values, &1))
    %{"values" => Enum.sort(values), "other" => List.first(other)} |> Enum.filter(fn {_k, v} -> Euclid.Exists.present?(v) end) |> Enum.into(%{})
  end

  # # #

  defp sorted_list_concat(a, b) do
    (List.wrap(a) ++ List.wrap(b)) |> Enum.sort() |> Enum.uniq()
  end
end
