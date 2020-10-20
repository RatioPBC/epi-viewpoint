defmodule Epicenter.Csv do
  alias Epicenter.Extra
  alias NimbleCSV.RFC4180, as: NimbleCsv

  def read(string, header_transformer, headers) when is_binary(string),
    do: read(string, header_transformer, headers, &NimbleCsv.parse_string/2)

  def read(stream, header_transformer, headers),
    do: read(stream, header_transformer, headers, &NimbleCsv.parse_stream/2)

  def read(input, header_transformer, [required: required_headers, optional: optional_headers], parser) do
    with {:ok, [provided_headers | rows]} <- parse(input, parser) do
      provided_headers = provided_headers |> Enum.map(&String.trim/1) |> header_transformer.()

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
                {header_key, Enum.at(row, header_index) |> Extra.String.trim()}
              end
            end

          {:ok, data}

        missing_headers ->
          {:error, :missing_headers, missing_headers |> Enum.sort()}
      end
    end
  end

  defp parse(input, parser) do
    {:ok, parser.(input, skip_headers: false)}
  rescue
    e ->
      hint = "make sure there are no spaces between the field separators (commas) and the quotes around field contents"
      {:invalid_csv, "#{e.message} (#{hint})"}
  end
end
