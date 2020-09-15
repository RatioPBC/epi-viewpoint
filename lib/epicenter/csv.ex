defmodule Epicenter.Csv do
  alias NimbleCSV.RFC4180, as: NimbleCsv

  def read(string, headers) when is_binary(string),
    do: read(string, headers, &NimbleCsv.parse_string/2)

  def read(stream, headers),
    do: read(stream, headers, &NimbleCsv.parse_stream/2)

  def read(input, [required: required_headers, optional: optional_headers], parser) do
    [provided_headers | rows] = parse(input, parser)
    provided_headers = provided_headers |> Enum.map(&String.trim/1)

    case required_headers -- provided_headers do
      [] ->
        headers =
          MapSet.intersection(
            MapSet.new(provided_headers),
            MapSet.union(MapSet.new(required_headers), MapSet.new(optional_headers))
          )

        header_indices =
          for header_key <- headers, into: %{} do
            {header_key, Enum.find_index(provided_headers, &(&1 == header_key))}
          end

        data =
          for row <- rows, into: [] do
            for {header_key, header_index} <- header_indices, into: %{} do
              {header_key, Enum.at(row, header_index) |> String.trim()}
            end
          end

        {:ok, data}

      missing_headers ->
        {:error, "Missing required columns: #{missing_headers |> Enum.sort() |> Enum.join(", ")}"}
    end
  end

  defp parse(input, parser) do
    parser.(input, skip_headers: false)
  rescue
    e ->
      hint = "make sure there are no spaces between the field separators (commas) and the quotes around field contents"
      raise NimbleCSV.ParseError, "#{e.message} (#{hint})"
  end
end
