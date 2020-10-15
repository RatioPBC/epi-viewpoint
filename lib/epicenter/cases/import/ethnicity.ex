defmodule Epicenter.Cases.Import.Ethnicity do
  @ethnicity_mapping %{
    "RefusedToAnswer" => %{"major" => "declined_to_answer", "detailed" => []},
    "NonHispanicOrNonLatino" => %{"major" => "not_hispanic", "detailed" => []},
    "HispanicOrLatino" => %{"major" => "hispanic", "detailed" => []}
  }

  @unknown_ethnicity %{"major" => "unknown", "detailed" => []}

  def build_attrs(%{"ethnicity" => ethnicity} = attrs),
    do: attrs |> Map.put("ethnicity", @ethnicity_mapping[ethnicity] || @unknown_ethnicity)

  def build_attrs(attrs),
    do: attrs |> Map.put("ethnicity", @unknown_ethnicity)
end
