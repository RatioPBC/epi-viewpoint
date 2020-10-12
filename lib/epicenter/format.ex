defmodule Epicenter.Format do
  def person(nil), do: ""
  def person(%{first_name: first_name, last_name: last_name}), do: [first_name, last_name] |> Euclid.Exists.join(" ")
end
