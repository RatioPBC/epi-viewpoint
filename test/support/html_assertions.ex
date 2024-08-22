defmodule EpiViewpoint.Test.HtmlAssertions do
  import ExUnit.Assertions

  alias EpiViewpoint.Extra
  alias EpiViewpoint.Test

  def assert_html_eq(left, right) do
    assert to_html_string(left) == to_html_string(right)
    left
  end

  def assert_contains_text(html, data_role, contained_text) do
    assert Test.Html.text(html, role: data_role) =~ contained_text
    html
  end

  defp to_html_string(string) when is_binary(string),
    do: string |> Extra.String.remove_marked_whitespace() |> Test.Html.normalize()

  defp to_html_string({:safe, _iodata} = safe_html),
    do: Phoenix.HTML.safe_to_string(safe_html) |> to_html_string()
end
