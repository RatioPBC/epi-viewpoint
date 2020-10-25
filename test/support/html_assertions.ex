defmodule Epicenter.Test.HtmlAssertions do
  import ExUnit.Assertions

  alias Epicenter.Test

  def assert_html_eq(left, right) do
    assert to_html_string(left) == to_html_string(right)
    left
  end

  defp to_html_string(string) when is_binary(string),
    do: Test.Html.normalize(string)

  defp to_html_string({:safe, _iodata} = safe_html),
    do: Phoenix.HTML.safe_to_string(safe_html) |> to_html_string()
end
