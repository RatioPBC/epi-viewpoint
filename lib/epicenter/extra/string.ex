defmodule Epicenter.Extra.String do
  alias Epicenter.Extra

  def add_numeric_suffix(s), do: "#{s}_#{Enum.random(1..99)}"
  def remove_numeric_suffix(s), do: String.replace(s, ~r[(\w+)_\d+$], "\\1")
  def add_placeholder_suffix(s), do: "#{s}_xx"

  def dasherize(list) when is_list(list), do: list |> Enum.map(&dasherize/1) |> Enum.join("-")
  def dasherize(item), do: item |> to_string() |> String.replace("_", "-")

  def pluralize(1, singular, _plural), do: "1 #{singular}"
  def pluralize(n, _singular, plural) when is_integer(n), do: "#{n} #{plural}"

  @doc "remove all whitespace following a backspace+v escape code"
  def remove_marked_whitespace(s), do: s |> String.replace(~r|\v\s*|, "")

  def remove_non_numbers(nil), do: nil
  def remove_non_numbers(s), do: s |> Elixir.String.replace(~r|[^\d]|, "")

  def sha256(s), do: :crypto.hash(:sha256, s) |> Base.encode16() |> String.downcase()

  def squish(nil), do: nil
  def squish(s), do: s |> trim() |> Elixir.String.replace(~r/\s+/, " ")

  def trim(nil), do: nil
  def trim(s) when is_binary(s), do: Elixir.String.trim(s)

  def underscore(list) when is_list(list), do: list |> Extra.Enum.reject_blank() |> Enum.map(&underscore/1) |> Enum.join("_")
  def underscore(item), do: item |> to_string() |> String.replace("-", "_")
end
