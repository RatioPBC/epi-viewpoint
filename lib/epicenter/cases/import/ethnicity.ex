defmodule Epicenter.Cases.Import.Ethnicity do
  @ethnicity_mapping %{
    "RefusedToAnswer" => %{"parent" => "Declined to answer", "children" => []},
    "NonHispanicOrNonLatino" => %{"parent" => "Not Hispanic, Latino/a, or Spanish origin", "children" => []},
    "HispanicOrLatino" => %{"parent" => "Hispanic, Latino/a, or Spanish origin", "children" => []}
  }

  @unknown_ethnicity %{"parent" => nil, "children" => nil}

  def build_attrs(%{"ethnicity" => ethnicity} = attrs),
    do: attrs |> Map.put("ethnicity", @ethnicity_mapping[ethnicity] || @unknown_ethnicity)

  def build_attrs(attrs),
    do: attrs
end
