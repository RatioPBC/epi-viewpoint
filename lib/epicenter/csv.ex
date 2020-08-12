defmodule Epicenter.Csv do
  alias NimbleCSV.RFC4180, as: NimbleCsv

  @header_keys ~w{first_name last_name dob sample_date result_date result}

  def read(string) when is_binary(string),
    do: read(string, &NimbleCsv.parse_string/2)

  def read(stream),
    do: read(stream, &NimbleCsv.parse_stream/2)

  def read(input, parser) do
    [headers | rows] = parser.(input, skip_headers: false)
    headers = headers |> Enum.map(&String.trim/1)

    header_indices =
      for header_key <- @header_keys, into: %{} do
        {header_key, Enum.find_index(headers, &(&1 == header_key))}
      end

    for row <- rows, into: [] do
      for {header_key, header_index} <- header_indices, into: %{} do
        {header_key, Enum.at(row, header_index) |> String.trim()}
      end
    end
  end
end
