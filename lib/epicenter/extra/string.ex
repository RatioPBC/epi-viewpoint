defmodule Epicenter.Extra.String do
  def squish(nil), do: nil
  def squish(s), do: s |> trim() |> Elixir.String.replace(~r/\s+/, " ")

  def trim(nil), do: nil
  def trim(s) when is_binary(s), do: Elixir.String.trim(s)
end
