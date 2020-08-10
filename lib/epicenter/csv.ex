defmodule Epicenter.Csv do
  alias NimbleCSV.RFC4180, as: NimbleCsv

  @header_keys ~w{first_name last_name dob sample_date result_date result}

  def import(string) do
    [headers | rows] = string |> NimbleCsv.parse_string(skip_headers: false)
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
