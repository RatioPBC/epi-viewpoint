defmodule Epicenter.Format do
  def format(%{first_name: first_name, last_name: last_name}),
    do: [first_name, last_name] |> Euclid.Exists.filter() |> Enum.join(" ")
end
