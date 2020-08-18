defmodule Epicenter.Csv do
  alias NimbleCSV.RFC4180, as: NimbleCsv

  def read(string, headers) when is_binary(string),
    do: read(string, headers, &NimbleCsv.parse_string/2)

  def read(stream, headers),
    do: read(stream, headers, &NimbleCsv.parse_stream/2)

  def read(input, [required: required_headers, optional: _optional_headers], parser) do
    [headers | rows] = parser.(input, skip_headers: false)
    headers = headers |> Enum.map(&String.trim/1)

    header_indices =
      for header_key <- required_headers, into: %{} do
        {header_key, Enum.find_index(headers, &(&1 == header_key))}
      end

    for row <- rows, into: [] do
      for {header_key, header_index} <- header_indices, into: %{} do
        {header_key, Enum.at(row, header_index) |> String.trim()}
      end
    end
  end
end
