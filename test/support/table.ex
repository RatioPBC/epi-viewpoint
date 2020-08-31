defmodule Epicenter.Test.Table do
  alias Epicenter.Extra
  alias Epicenter.Test

  def table_contents(parsed_html, opts \\ []) when is_list(parsed_html) do
    desired_columns = opts |> Keyword.get(:columns)
    desired_row = opts |> Keyword.get(:row)
    css = opts |> Keyword.get(:css)
    role = opts |> Keyword.get(:role)
    include_headers = opts |> Keyword.get(:headers, true)

    table =
      parsed_html
      |> Floki.find(css_query(css, role))
      |> Floki.raw_html()

    headers =
      table
      |> Floki.parse_fragment!()
      |> Floki.find("thead tr[data-role=table-column-names] th")
      |> Enum.map(&Test.Html.text(&1))

    body =
      table
      |> Floki.parse_fragment!()
      |> Floki.find("tbody tr")
      |> Enum.map(fn row ->
        row
        |> Floki.find("th, td")
        |> Enum.map(&Test.Html.text(&1))
        |> Enum.map(&Extra.String.squish(&1))
      end)

    {headers, body}
    |> restrict_columns(desired_columns)
    |> restrict_row(desired_row)
    |> combine(include_headers)
    |> rotate(!!desired_row)
  end

  defp restrict_columns({headers, body}, nil), do: {headers, body}

  defp restrict_columns({headers, body}, desired_columns) do
    column_indices = Extra.Enum.find_indices(headers, desired_columns)
    header_subset = headers |> Extra.Enum.fetch_multiple(column_indices)
    body_subset = body |> Enum.map(&Extra.Enum.fetch_multiple(&1, column_indices))

    {header_subset, body_subset}
  end

  defp restrict_row({headers, body}, nil), do: {headers, body}

  defp restrict_row({headers, body}, desired_row),
    do: {headers, [Extra.Enum.at!(body, desired_row)]}

  defp combine({_headers, body}, false), do: body
  defp combine({headers, body}, true) when length(headers) == 0, do: body
  defp combine({headers, body}, true), do: [headers] ++ body

  defp rotate(list, false), do: list
  defp rotate([header_row, body_row], true), do: Enum.zip(header_row, body_row) |> Enum.into(%{})
  defp rotate(_list, true), do: raise("Can only rotate a table with one body row")

  defp css_query(nil, role), do: "[data-role=#{role}]"
  defp css_query(css, nil), do: css
  defp css_query(css, role), do: "#{css}[data-role=#{role}]"
end
