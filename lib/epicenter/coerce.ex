defmodule Epicenter.Coerce do
  def to_string_or_nil(nil), do: nil
  def to_string_or_nil([]), do: nil
  def to_string_or_nil([nil]), do: nil
  def to_string_or_nil(s) when is_binary(s), do: s
  def to_string_or_nil([s]) when is_binary(s), do: s
  def to_string_or_nil(other), do: raise("Expected nil, a string, or a list with one string, got: #{inspect(other)}")
end
