defmodule Epicenter.Cases.Import.Ethnicity do
  @ethnicity_mapping %{
    "RefusedToAnswer" => %{"parent" => "declined_to_answer", "children" => []},
    "NonHispanicOrNonLatino" => %{"parent" => "not_hispanic", "children" => []},
    "HispanicOrLatino" => %{"parent" => "hispanic", "children" => []}
  }

  @unknown_ethnicity %{"parent" => "unknown", "children" => []}

  def build_attrs(%{"ethnicity" => ethnicity} = attrs),
    do: attrs |> Map.put("ethnicity", @ethnicity_mapping[ethnicity] || @unknown_ethnicity)

  def build_attrs(attrs),
    do: attrs |> Map.put("ethnicity", @unknown_ethnicity)
end
