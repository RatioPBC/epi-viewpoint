defmodule Epicenter.DateParser do
  @mm_dd_yyyy_regex ~r|(?<mm>\d{2})[-/](?<dd>\d{2})[-/](?<yyyy>\d{4})|

  def parse_mm_dd_yyyy(mm_dd_yyyy) when is_binary(mm_dd_yyyy) do
    captures = Regex.named_captures(@mm_dd_yyyy_regex, String.trim(mm_dd_yyyy))

    year = captures["yyyy"] |> to_integer()
    month = captures["mm"] |> to_integer()
    day = captures["dd"] |> to_integer()

    if [{year, 1850..2050}, {month, 1..12}, {day, 1..31}] |> Enum.all?(&valid?/1),
      do: Date.new(year, month, day),
      else: {:error, "Invalid mm-dd-yyyy format: #{mm_dd_yyyy}"}
  end

  def parse_mm_dd_yyyy(%Date{} = date) do
    {:ok, date}
  end

  def parse_mm_dd_yyyy!(mm_dd_yyyy) do
    case parse_mm_dd_yyyy(mm_dd_yyyy) do
      {:ok, date} -> date
      {:error, message} -> raise message
    end
  end

  defp to_integer(nil), do: nil
  defp to_integer(s) when is_binary(s), do: s |> String.trim() |> String.to_integer()
  defp to_integer(i) when is_integer(i), do: i

  defp valid?({integer, range}) when is_integer(integer), do: Enum.member?(range, integer)
  defp valid?({_date, _range}), do: false
end
