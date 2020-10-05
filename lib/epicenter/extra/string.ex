defmodule Epicenter.Extra.String do
  def pluralize(1, singular, _plural), do: "1 #{singular}"
  def pluralize(n, _singular, plural) when is_integer(n), do: "#{n} #{plural}"

  def remove_non_numbers(nil), do: nil
  def remove_non_numbers(s), do: s |> Elixir.String.replace(~r|[^\d]|, "")

  def squish(nil), do: nil
  def squish(s), do: s |> trim() |> Elixir.String.replace(~r/\s+/, " ")

  def trim(nil), do: nil
  def trim(s) when is_binary(s), do: Elixir.String.trim(s)
end
