defmodule Epicenter.DateParser do
  @mm_dd_yyyy_regex ~r|(?<mm>\d\d?)[-/](?<dd>\d\d?)[-/](?<yyyy>\d{2,4})|

  def parse_mm_dd_yyyy(nil), do: {:ok, nil}
  def parse_mm_dd_yyyy(""), do: {:ok, nil}

  def parse_mm_dd_yyyy(mm_dd_yyyy) when is_binary(mm_dd_yyyy) do
    captures = Regex.named_captures(@mm_dd_yyyy_regex, String.trim(mm_dd_yyyy))

    year = captures["yyyy"] |> to_integer()
    month = captures["mm"] |> to_integer()
    day = captures["dd"] |> to_integer()

    year = normalize_year(year)

    with :ok <- in_range?(year, month, day),
         {:ok, parsed} <- Date.new(year, month, day) do
      {:ok, parsed}
    else
      :out_of_range -> {:error, [user_readable: "Invalid mm-dd-yyyy format: #{mm_dd_yyyy}"]}
      {:error, :invalid_date} -> {:error, [user_readable: "Invalid date: #{mm_dd_yyyy}"]}
    end
  end

  def parse_mm_dd_yyyy(%Date{} = date) do
    {:ok, date}
  end

  def parse_mm_dd_yyyy!(mm_dd_yyyy) do
    case parse_mm_dd_yyyy(mm_dd_yyyy) do
      {:ok, date} -> date
      {:error, message} -> raise Epicenter.DateParsingError, message
    end
  end

  defp normalize_year(year) do
    current_year = Date.utc_today().year
    current_century = current_year - rem(current_year, 100)
    last_century = current_century - 100

    cond do
      year > 99 -> year
      current_century + year <= current_year -> current_century + year
      true -> last_century + year
    end
  end

  defp to_integer(nil), do: nil
  defp to_integer(s) when is_binary(s), do: s |> String.trim() |> String.to_integer()
  defp to_integer(i) when is_integer(i), do: i

  defp in_range?(year, month, day) do
    if [{year, 1850..2050}, {month, 1..12}, {day, 1..31}] |> Enum.all?(&in_range?/1),
      do: :ok,
      else: :out_of_range
  end

  defp in_range?({integer, range}) when is_integer(integer), do: Enum.member?(range, integer)
  defp in_range?({_date, _range}), do: false
end
