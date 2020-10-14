defmodule Epicenter.Cases.Import.Ethnicity do
  def build_attrs(%{"ethnicity" => ethnicity} = attrs),
    do: attrs |> Map.put("ethnicity", %{"parent" => ethnicity, "children" => []})

  def build_attrs(attrs),
    do: attrs
end
